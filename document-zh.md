# $\lambda$ Log

**LamLog (Lambda Logic)** 是一个类似Prolog的逻辑型程序设计语言，通过事实和规则构建知识库，支持用户查询，通过模式匹配推导答案，适用于符号计算与逻辑问题求解。

## 功能

用户可以定义事实和规则，构建自己的知识库，然后可以查询事实是否包含于知识库。

相关概念：
* 事实：构成知识库的原子，指定一条关系。例如`parent(alice, bob)`，定义了alice是bob的父辈。
* 规则：扩展知识库的模式，知识库可以通过应用规则得到新的事实。例如`grandparent(X, Y) :- parent(X, Z), parent(Z, Y)`，定义了什么是祖辈关系。
* 查询：有两种方式，一种是不带变量的查询，如`parent(alice, bob)`，相当于一般疑问句，可以视为查询事实是否成立；另一种是带变量的查询，如`parent(X, Y)`，相当于特殊疑问句，可以视为查询能够匹配一种关系的事实。
* 变量：模式中的变量，例如`X`，该语言中使用大写字母表示变量，从而与事实中的常量区分。

除了普通的脚本运行，LamLog还支持REPL，用户可以交互地增删知识库，列出知识库内容和进行查询。REPL的语法与脚本中稍有不同，会在语法部分介绍。

LamLog实现了基本的错误检查，对于大多数异常情况会输出原因；在REPL中，操作知识库的语句会输出true或false，表明操作是否成功。

## 运行

首先确保环境中有Racket，然后在命令行中运行：

```sh
racket lamlog.rkt -f <file> [-t]
```

其中：
* `-f <file>`：指定要运行的脚本文件。
* `-t`：可选参数，存在时表示以测试模式运行，会在运行脚本后退出，而不是进入REPL。

## 语法

LamLog 语言的语法主要由以下几种结构组成：

1.  **变量 (Variables)**:
    *   由单个大写字母组成的符号表示变量。
    *   S-expression 形式：`<variable-name>`
    *   例如：`X`, `Y`

2.  **常量 (Atoms)**:
    *   以小写字母开头的符号或数字表示常量。
    *   S-expression 形式：`<atom-value>`
    *   例如：`john`, `mary`, `123`, `true`

3.  **复合项 (Compound Terms)**:
    *   由一个函数名（functor）和零个或多个参数组成。函数名是原子，参数可以是变量、原子或复合项。
    *   S-expression 形式：`(<functor> <arg1> <arg2> ...)`
    *   例如：`(succ 0 1)`, `(parent X bob)`

4.  **事实 (Facts)**:
    *   一个没有主体的复合项，表示一个已知的事实。以句点结尾。
    *   S-expression 形式：`(<functor> <atom-value1> <atom-value2> ...).`
    *   例如：`(parent john mary).`, `(male john).`

5.  **规则 (Rules)**:
    *   由一个头部（head）和一个或多个主体（body）组成，表示一个逻辑规则。如果主体中的所有条件都为真，则头部为真。以句点结尾。
    *   S-expression 形式：`(<head> :- <body1> <body2> ...).`
    *   头部和主体都是复合项。
    *   例如：`((grandparent X Z) :- (parent X Y) (parent Y Z)).`

6.  **查询 (Queries)**:
    *   一个没有主体的复合项，表示要查询的目标。以问号结尾。
    *   S-expression 形式：`(<functor> <arg1> <arg2> ...)?`
    *   例如：`(parent john X)?`, `(less-than X Y)?`

### REPL语法

REPL 语法与脚本语法略有不同，用户在REPL中输入的是操作命令。

1. 查询：`(predicate arg1 arg2 ...)?`

2. 添加事实：`assertz((predicate arg1 arg2 ...)).`

3. 添加规则：`assertz(((head) :- (body1) (body2) ...)).`

4. 删除子句：`retract((clause)).`

5. 查看知识库：`list.`

6. 退出：`exit.`

所有语句必须以 `.` 结尾，查询必须以 `?` 结尾。

示例：

```sh
$ racket lamlog.rkt
LamLog REPL. Enter queries like: (grandparent X carol)?
To add a fact: assertz((parent alice bob)).
To add a rule: assertz(((grandparent X Y) :- (parent X Z) (parent Z Y))).
To remove a clause: retract((parent alice bob)).
To list all clauses: list.
To exit: exit.

?- assertz((parent alice bob)).
true.

?- assertz((parent bob carol)).
true.

?- assertz(((grandparent X Y) :- (parent X Z) (parent Z Y))).
true.

?- list.
Current clauses in KB:
  (parent alice bob).
  (parent bob carol).
  (grandparent X Y) :- (parent X Z), (parent Z Y).

?- (grandparent A B)?
true.
(grandparent alice carol)

?- exit.
Goodbye.
```

## 实现

`lamlog-core.rkt` 实现了 LamLog 的核心功能，包括解析、求值、查询等。
`lamlog-script.rkt` 实现了 LamLog 的脚本运行功能，用户可以通过脚本文件运行 LamLog。
`lamlog-repl.rkt` 实现了 LamLog 的 REPL 功能，用户可以在命令行中交互地增删知识库，列出知识库内容和进行查询。
`lamlog.rkt` 是 LamLog 的入口文件，用户可以通过该文件运行 LamLog。

`lamlog-core.rkt`中有三个重要的函数：`apply-subst`，`unify`和`resolve`。

### `apply-subst`：应用替换

**功能**：将变量替换映射应用到一个项（term）上，得到替换后的结果。

**原理**：

* 如果是变量（`var`），就查找这个变量是否在替换列表 `subst` 中有绑定，如果有，递归地继续替换它对应的值；如果没有，原样返回。
* 如果是复合项（`compound`），则对其所有参数递归应用替换。
* 原子项（`atom`）不变。

**示例**：

```
subst = [(X, alice), (Y, bob)]
term = (likes X Y)
=> apply-subst 后为 (likes alice bob)
```

### `unify`：统一

**功能**：找出使两个项相等的变量替换集。如果找不到，就返回 `#f`。

**原理**：

* 首先对两个项应用当前的替换 `subst`。
* 如果两项相等，不做任何操作，返回原来的 `subst`。
* 如果某个项是变量，添加绑定关系。
* 如果两个是结构相同的复合项，就尝试递归统一它们每个参数。
* 如果都不是上述情况，统一失败，返回 `#f`。

**示例**：

```
unify(likes(X, bob), likes(alice, Y), [])
=> [(X, alice), (Y, bob)]
```

### `resolve`：目标求解器

**功能**：对给定目标列表 `goals`，用知识库 `kb` 和初始替换 `subst` 来进行逻辑推理，返回所有满足目标的替换集。

**原理**：

1. 如果目标列表为空，说明所有目标都成功了，返回当前替换 `subst`。
2. 否则取出第一个目标 `g`：

   * 遍历所有知识库中的子句：

     * 如果是 `fact`（事实），尝试用 `unify` 和 `g` 统一。如果成功，则继续解决剩下的目标。
     * 如果是 `rule`（规则），先**变量重命名**，再和 `g` 统一。如果成功，就把规则体（rule body）加入剩余目标继续解决。
3. 所有可能的解通过 `append` 组合起来。

**示例**：
假设有如下规则：

```
(parent alice bob)
(parent bob carol)
(grandparent X Y :- parent X Z, parent Z Y)
```

查询 `(grandparent alice X)` 就会按规则递归推理，直到找到 `subst = [(X, carol)]`。

### 变量重命名

**功能**：在`resolve`中每次使用规则时都会进行变量重命名，这是为了避免变量名冲突：规则中使用的变量名应该是可以任意替换的。例如对于查询`(grandparent alice X)`，如果不进行变量重命名，那么规则中的`X`就会与查询中的`X`冲突，导致无法正确匹配。

**原理**：

1. `collect-vars`/`collect-vars-clause`：从一个项或子句中收集所有变量名。
2. `fresh-var-name`：为每个变量名生成一个唯一的新变量名，如`X`变成`X_17`。
3. `var-map`：构建变量映射，将旧变量名映射到新变量名。
4. `rename-vars-in-term`/`rename-vars-in-clause`：递归地将原 term/clause 中的变量名字替换成新名字，生成一个干净的子句副本。

## 测试

`samples/` 目录下有一些示例程序（无后缀名的是源文件，对应的.txt文件的是预期输出），可以通过 `racket lamlog.rkt -f <sample-file> -t`运行。测试脚本`tester.py`可以自动运行所有测试样例。

- `ancestor` 祖先关系。
- `graph` 图和连通性。
- `parent` 父辈和祖辈关系。
- `integer` 自然数。
- `permission` 权限检查。

测试用例展示了该语言的一些缺陷：

- `graph`中如果三个点成环，解释器在解析查询时会陷入死循环。要解决该问题需要记录已经访问过的点，避免重复访问，实现起来比较复杂。
- `parent`中允许了定义一个与现有事实冲突的事实。能想到的一种解决方式是在定义事实时检查是否能与现有事实unify（实际上就是做一次查询），但即便不能unify也分两种情况：一种是新定义的事实与现有事实冲突，另一种是新定义的事实与现有事实无关。要区分两者需要检查新定义的事实中包含的常量是否全部在知识库中存在，实现起来同样比较复杂。
