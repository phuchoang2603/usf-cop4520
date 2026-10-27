from pathlib import Path
import re
import zipfile

from pypdf import PdfReader
from reportlab.lib import colors
from reportlab.lib.pagesizes import letter
from reportlab.lib.styles import ParagraphStyle, getSampleStyleSheet
from reportlab.platypus import KeepTogether, Paragraph, SimpleDocTemplate, Spacer, Table, TableStyle

root = Path(__file__).resolve().parents[1]
log = (root / 'results/comparison-558065.out').read_text()
assert 'ALL BENCHMARKS PASSED' in log
cpu = {}
gpu = {}
for line in log.splitlines():
    fields = line.split(',')
    if fields[0] == 'CPU':
        cpu[int(fields[1])] = None if fields[2] == 'N/A' else float(fields[2])
    if fields[0] == 'MEAN':
        gpu[fields[1], int(fields[2])] = float(fields[3])

styles = getSampleStyleSheet()
styles.add(ParagraphStyle(name='Body', fontName='Helvetica', fontSize=10, leading=13, spaceAfter=7))
styles.add(ParagraphStyle(name='Section', fontName='Helvetica-Bold', fontSize=11, leading=14, spaceBefore=7, spaceAfter=4))
styles.add(ParagraphStyle(name='ReportTitle', fontName='Helvetica-Bold', fontSize=16, leading=20, alignment=1, spaceAfter=8))
styles.add(ParagraphStyle(name='Small', fontName='Helvetica', fontSize=8, leading=10, spaceAfter=6))
content = []


def p(text):
    content.append(Paragraph(text, styles['Body']))


def h(text):
    content.append(Paragraph(text, styles['Section']))


def table(rows, widths):
    item = Table(rows, colWidths=widths, hAlign='LEFT')
    item.setStyle(TableStyle([
        ('FONTNAME', (0, 0), (-1, 0), 'Helvetica-Bold'),
        ('FONTNAME', (0, 1), (-1, -1), 'Helvetica'),
        ('FONTSIZE', (0, 0), (-1, -1), 9),
        ('BACKGROUND', (0, 0), (-1, 0), colors.HexColor('#eeeeee')),
        ('LINEBELOW', (0, 0), (-1, 0), 0.5, colors.grey),
        ('TOPPADDING', (0, 0), (-1, -1), 6),
        ('BOTTOMPADDING', (0, 0), (-1, -1), 6),
    ]))
    content.append(KeepTogether([item, Spacer(1, 8)]))


content.append(Paragraph('COP4520 Project 2 Report', styles['ReportTitle']))
p('Felix Hoang | NetID: phuchoang')
h('Optimized CUDA techniques for histogram computation')
p('The CPU reference remains the single-threaded brute-force SDH algorithm from Project 1. Project 2 optimizes the GPU implementation, rather than changing the CPU algorithm. All versions use the same double-precision coordinates, BOX_SIZE = 23000, and srand(1). Every unordered pair is counted once, and the histogram uses 64-bit counts.')
h('Utilizing high-speed shared memory')
p('A two-dimensional grid divides the point pairs into tile pairs. Each thread retains one point in registers, while neighboring threads cooperatively load the second tile into shared memory. The block reuses that tile for its distance calculations, reducing repeated global-memory reads. This goes beyond Project 1, which keeps the output histogram in shared memory but repeatedly reads the input points from global memory.')
h('Ensuring safe concurrent updates')
p('The kernel uses atomicAdd to avoid lost updates. When the histogram fits, each block accumulates into its own shared-memory histogram, synchronizes, and adds its nonzero counts to the global histogram. The program checks the GPU shared-memory limit after reserving the point tile. If the histogram is too large, the same tiled kernel updates the global histogram directly. This fallback satisfies the Project 2 requirement to support histograms larger than per-block shared memory.')
h('Global memory access and workload distribution')
p('Threads load neighboring point records and reuse the shared tile. The retained array of atom structs has strided coordinate accesses across threads, so this implementation does not claim fully coalesced coordinate loads. Separate coordinate arrays could improve this, but were omitted to keep the change small. Tile-pair scheduling distributes the triangular pair space more evenly than assigning a complete remaining row to each thread. Checks for j &gt; i and the final partial tile prevent duplicate pairs and invalid accesses. Rounded double multiply/add operations preserve CPU agreement near bucket boundaries.')
h('Overview')
p('The implementation combines input tiling, register reuse, and block-local histogram privatization in one kernel. The supplied block size is used directly. CUDA events surround the kernel launch, and the stop event is synchronized before reading the elapsed time. Allocation, histogram clearing, CPU computation, transfers, and printing are excluded from GPU kernel timing. Valid program output contains only the CPU histogram, GPU histogram, differences, and total optimized kernel execution time.')
h('Comparative analysis of spatial distance histogram')
p('Matching the sample report, the main comparison uses <b>bucket width 256 and block size 128</b>, with 10,000, 100,000, and 500,000 points. Measurements were collected on GAIVI using a GeForce GTX 1080 Ti and CUDA 11.4.48. The separate benchmark includes the actual Project 1 and Project 2 source files without changing their kernels. All GPU versions are measured with synchronized CUDA events using the same input and compiler options. GPU entries are means of three runs; CPU entries are one timed call to the original CPU baseline, excluding setup and output.')
rows = [['Points', 'CPU (s)', 'P1 global (ms)', 'P1 shared (ms)', 'P2 tiled (ms)']]
for n in [10000, 100000, 500000]:
    rows.append([
        f'{n:,}', 'N/A' if cpu[n] is None else f'{cpu[n]:.3f}',
        f'{gpu["Project1-global", n] * 1000:.3f}',
        f'{gpu["Project1-shared", n] * 1000:.3f}',
        f'{gpu["Project2-tiled", n] * 1000:.3f}',
    ])
table(rows, [75, 80, 115, 115, 110])
rows = [['Points', 'CPU / Project 2', 'P1 global / P2', 'P1 shared / P2']]
for n in [10000, 100000, 500000]:
    optimized = gpu['Project2-tiled', n]
    rows.append([
        f'{n:,}', 'N/A' if cpu[n] is None else f'{cpu[n] / optimized:.2f}x',
        f'{gpu["Project1-global", n] / optimized:.2f}x',
        f'{gpu["Project1-shared", n] / optimized:.2f}x',
    ])
table(rows, [75, 140, 140, 140])
p('Each speedup is the baseline computation time divided by the Project 2 kernel time. Values below 1 mean Project 2 was slower. This compares computation only, not end-to-end application time. The 500,000-point CPU run is omitted, matching the sample report\'s N/A entry; no CPU time is estimated. These are new measurements, not copied sample timings.')
p(f'At 10,000 points, Project 2 was {gpu["Project1-shared", 10000] / gpu["Project2-tiled", 10000]:.2f}x faster than the Project 1 shared-memory kernel. At 100,000 points, Project 2 took {gpu["Project2-tiled", 100000] * 1000:.3f} ms versus {gpu["Project1-shared", 100000] * 1000:.3f} ms for Project 1 shared memory, so tiling did not improve this case. Extra tile blocks, synchronization, and histogram initialization can offset input reuse; no profiler-based attribution was performed. The results demonstrate that the benefit depends on problem size rather than guaranteeing that every added optimization is faster.')
h('Correctness and additional experiments')
p('At 10,000 and 100,000 points, every timed GPU run matched the CPU in every bucket. For 500,000 points, the CPU baseline was not run: all GPU versions agreed with the first Project 1 global-memory result and had the expected 124,999,750,000 total pairs. This larger case is GPU cross-validation, not a full CPU comparison.')
p('The earlier validation job 557880 passed eight valid cases, including 1 and 2 points, a 257-point partial block with 96 threads, and multiple block sizes. Every bucket matched the CPU. Eight invalid-input cases were rejected. At width 5 and block size 256, 7,968 histogram buckets require 63,744 bytes, exceeding the 49,152-byte per-block shared-memory limit even before the point tile. The global-histogram fallback passed this case. Single-run times at 10,000 points and width 500 were 8.869, 9.685, and 10.541 ms for block sizes 128, 256, and 512. These supplementary measurements use different settings from the main comparison.')
p('The program compiled and ran successfully using the course run script.')

report = root / 'proj2-report.pdf'
SimpleDocTemplate(str(report), pagesize=letter, leftMargin=42, rightMargin=42, topMargin=32, bottomMargin=32, title='COP4520 Project 2 Report', author='Felix Hoang').build(content)
reader = PdfReader(report)
assert len(reader.pages) <= 3
text = '\n'.join(page.extract_text() for page in reader.pages)
assert '500,000' in text and 'CPU (s)' in text
archive = root / 'proj2-phuchoang.zip'
with zipfile.ZipFile(archive, 'w', zipfile.ZIP_DEFLATED) as z:
    for name in ['proj2.cu', 'proj2-report.pdf']:
        z.write(root / name, 'proj2-phuchoang/' + name)
with zipfile.ZipFile(archive) as z:
    assert z.testzip() is None
    assert len(z.namelist()) == 2
    for name in ['proj2.cu', 'proj2-report.pdf']:
        assert z.read('proj2-phuchoang/' + name) == (root / name).read_bytes()
print('Verified report pages:', len(reader.pages))
print('Verified ZIP:', archive)
