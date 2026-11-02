# Makes a counting copy of Kompost: the interpreter loop tallies every dynamic
# window of four instructions, and --stats prints the tallies. Used by bin/profile.
src, dst = sys.argv[1], sys.argv[2]
for f in os.listdir(src):
    if f.endswith('.av') or f == 'aver.toml': shutil.copy(os.path.join(src, f), dst)
os.chdir(dst)
s=open('exec.av').read()
s=s.replace("    pinned: List<Val>\n    steps: Int\n","    pinned: List<Val>\n    steps: Int\n    hist: Map<String, Int>\n",1)
s=s.replace("steps = 0)","steps = 0, hist = {})")
i=s.index("fn loop(x: Inst, f: Frame, calls: List<Frame>, s: Store, n: Int) -> Outcome\n")
j=s.index("\n", s.index("    ?", i))+1
s=s[:i]+s[i:j].replace("s: Store, n","s9: Store, n")+"    s = Store.update(s9, hist = bump(s9.hist, f.code, f.pc))\n"+s[j:]
a=open('ast.av').read()
blk=a[a.index('type Instr\n'):]; blk=blk[:blk.index('\n\n')]
arms=[]
for line in blk.split('\n')[1:]:
    m=re.match(r'(\w+)(\((.*)\))?$',line.strip()); name=m.group(1); args=m.group(3); n=0
    if args:
        d=0;n=1
        for ch in args:
            if ch=='<':d+=1
            elif ch=='>':d-=1
            elif ch==',' and d==0:n+=1
    arms.append(f'        Instr.{name}' + (f"({', '.join(['_']*n)})" if n else "") + f' -> "{name}"')
s+='''
fn bump(h: Map<String, Int>, code: Vector<Instr>, pc: Int) -> Map<String, Int>
    ? "x"
    k = "{keyOf(Vector.get(code, pc))} {keyOf(Vector.get(code, pc + 1))} {keyOf(Vector.get(code, pc + 2))} {keyOf(Vector.get(code, pc + 3))}"
    c = Option.withDefault(Map.get(h, k), 0)
    Map.set(h, k, c + 1)

fn keyOf(i: Option<Instr>) -> String
    ? "x"
    match i
        Option.Some(v) -> detail(v)
        Option.None -> "fallout"

fn detail(i: Instr) -> String
    ? "x"
    match i
        Instr.Bin(op) -> "Bin{op}"
        Instr.Un(op) -> "Un{op}"
        Instr.Op2(op, a, b, k, out, oa, sk) -> "Op2[{op},{a},{b},{out},{sk}]"
        _ -> nameOf(i)

fn nameOf(i: Instr) -> String
    ? "x"
    match i
'''+'\n'.join(arms)+'\n'
open('exec.av','w').write(s)
m=open('main.av').read()
m=m.replace('["--stats", path, ..rest] -> report(statsOf(runFileStore(path, "_start", [], rest)))','["--stats", path, ..rest] -> printHist(runFileStore(path, "_start", [], rest))')
m+='''
fn printHist(r: Result<Ran, String>) -> Int
    ? "x"
    ! [Console.print]
    u = printRes(r)
    0

fn printRes(r: Result<Ran, String>) -> Unit
    ? "x"
    ! [Console.print]
    match r
        Result.Ok(ran) -> printAll(Map.entries(ran.s.hist))
        Result.Err(e) -> Console.print(e)

fn printAll(es: List<Tuple<String, Int>>) -> Unit
    ? "x"
    ! [Console.print]
    match es
        [] -> Console.print("")
        [e, ..rest] -> printOne(e, rest)

fn printOne(e: Tuple<String, Int>, rest: List<Tuple<String, Int>>) -> Unit
    ? "x"
    ! [Console.print]
    match e
        (k, v) -> printTwo(k, v, rest)

fn printTwo(k: String, v: Int, rest: List<Tuple<String, Int>>) -> Unit
    ? "x"
    ! [Console.print]
    Console.print("{v} {k}")
    printAll(rest)
'''
open('main.av','w').write(m)
