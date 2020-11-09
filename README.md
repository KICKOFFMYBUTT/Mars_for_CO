# Mars - modified

Mars modified for BUAA Computer Organization Course

Based on [Mars](http://courses.missouristate.edu/kenvollmar/mars/)

*AUTHOR: dhy*

## 修改内容

1. 添加了课程要求的对于写寄存器和写内存的输出信息

   写寄存器： `@00003000: $17 <= 12340000` 

   写内存： `@00003008: *00000004 <= baadf00d` 

2. 默认的 Memory Configuration 为 CompactDataAtZero ，无论是否在命令行中显式地给出 `mc CompactDataAtZero` 参数。

3. 增加了一条自定义指令（ `bnoeq` created by Ganten， opcode is 010010 ）

## 修改方法

首先要会解开 jar 包，这一步直接用压缩文件管理器解开即可。

所有的源代码均位于工程根目录下的 `mars` 子目录下。

如果考场里有 IDEA ，就直接用 IDEA 重新打包 jar 。如果考场没有，则按照如下步骤：（全程应在 Mars 项目文件夹的根目录下进行操作！不要 cd 到子目录或外层目录！）

1. 将每个修改过的 `.java` 文件重新编译成相应的 `.class` 。

   参考命令： `javac mars\mips\instructions\InstructionSet.java` 

2. 利用 `jar` 命令重新打包。

   参考命令： `jar cvfm Mars_m.jar META-INF\MANIFEST.MF .` 

为了方便操作，在包内放了一个批处理 `compile.bat` ，最后一行是 jar 打包，前面注释掉的是重新编译修改过的代码。

### 添加输出信息

#### 寄存器

向 `mars.mips.hardware.Register` 类的 `setValue` 方法中加入输出信息，利用 `SystemIO.printString` 方法。要输出固定 8 位，前导零补齐的十六进制数可以用 `String.format("%08x", num)` 方法。**注意这里的PC值要手动减4**（运行的时候就可以看出来区别了）。

```java
       public synchronized int setValue(int val){
         int old = value;
         value = val;
         // Add Register Output: TIME@PC: $REG <= DATA
           String regName = "$" + this.getNumber();
           if (this.getNumber() == 33 || this.getNumber() == 34) regName = "$" + this.getName();
           if (this.getNumber() != 32) // Attention: Program Counter should -4
            SystemIO.printString("@" + String.format("%08x", RegisterFile.getProgramCounter() - 4) +
                    ": $" + String.format("%-2d", this.getNumber() )+ " <= " + String.format("%08x", value) + "\n");
         notifyAnyObservers(AccessNotice.WRITE);
         return old;
      }
```

#### 内存

修改点位于 `mars.mips.hardware.Memory` ，同理，PC值应手动减4 。

注意：要求的内存输出信息是对**字**的写入，对于 `sb` 或者 `sh` 指令，应该输出的是要写入的字节/半字与内存中原有的字的拼接。所以这里首先要对地址 `address` 按字截断（先右移2位再左移2位），然后可以借用 `getRawWord` 这个方法取出刚写入内存的这个字。

```java
      public int set(int address, int value, int length) throws AddressErrorException {
         int oldValue = 0;
         if (Globals.debug) System.out.println("memory["+address+"] set to "+value+"("+length+" bytes)");
         int relativeByteAddress;
         /* 
          * omitted some code ......
          */
          // TIME@PC: *ADDR <= DATA
         SystemIO.printString("@" + String.format("%08x", RegisterFile.getProgramCounter() - 4) + ": *" +
               String.format("%08x", ((address >> 2) << 2)) + " <= " + String.format("%08x", getRawWord(((address >> 2) << 2))) + "\n");
          notifyAnyObservers(AccessNotice.WRITE, address, length, value);
         return oldValue;
      }
```

### 修改默认内存配置

在 `mars.Settings` 类中修改 `defaultStringSettingsValues` ，将第 3 项(下标从 0 开始)元素的空串修改成 `"CompactDataAtZero"` 。

### 添加非标准指令

修改 `mars.mips.instructions.InstructionSet` 类的 `populate` 方法，这个方法内的代码结构非常明显（有大量相似的代码，每一段以 `instructionList.add` 开头的代码均代表一条指令。

每个指令( `BasicInstruction` )的要素：调用示例 `example` ，描述 `description` ，格式 `format` ，二进制格式 `operMask` ，执行行为（ `simulate` 方法）。

添加的一个自定义指令的参考：

```java
instructionList.add(
    new BasicInstruction("bnoeq $t1,$t2,label",
      "Branch if number of one equal : Branch to statement at label's address if the ones in 2's Complement of $t1 and $t2 are equal",
      BasicInstructionFormat.I_BRANCH_FORMAT,
      "010010 fffff sssss tttttttttttttttt",
      new SimulationCode()
      {
          public void simulate(ProgramStatement statement) throws ProcessingException
          {
              int[] operands = statement.getOperands();
              int x1 = RegisterFile.getValue(operands[0]), x2 = RegisterFile.getValue(operands[1]);
              int cnt1 = 0, cnt2 = 0;
              for (int i = 0; i <= 31; i++) {
                  if ((x1 & (1 << i)) != 0) { // the i-th bit is not zero
                    cnt1++;
                  }
                  if ((x2 & (1 << i)) != 0) { // the i-th bit is not zero
                      cnt2++;
                  }
              }
              if (cnt1 == cnt2)
              {
                  processBranch(operands[2]);
              }
          }
      }));
```

每一种指令都有很多现成的范例，拿不准咋写的话就参考一个相同类型的！

## Mars 的程序结构概览

解开 jar 包之后，首先在根目录有一个主类 `Mars` 这也是整个程序的执行入口。

由于 Mars 的工程量相对较大，因此可以从主类入口处利用 IDEA 的断点调试，模拟一遍 Mars 的启动过程，可以较快地对整个结构有初步的了解。（或者按住 Ctrl 键点击入口方法，可以深入到方法内部）

一些比较有用的内容：

-  `mars.MarsLaunch` 类：启动 Mars，该类的注释中含有 Mars 的命令行参数文档。
  - 构造方法：启动 Mars 的过程，其中包含有判断是否启动图形界面。
  -  `parseCommandArgs` 方法：解析各个命令行参数的方法，可以很清晰地观察到每个命令行参数分别对应哪个类，快速定位要修改/添加的功能位于哪个类中。
    - **重要信息** ：命令行参数 `mc` ，找到判断此参数的代码可知，内存地址配置与 `MemoryConfiguration` 类有关。
  -  `launchIDE` ：启动图形界面，其中构造了一个 `VenusUI` 类，这个类为整个 Mars 的主图形界面。
-  `mars.venus.VenusUI` ： Mars 的图形界面主体，可以看得到常用的各种按钮。
  - 找到 `Run` 按钮，其绑定的 `Action` 为 `RunGoAction` ，进入该事件类的 `actionPerformed` 方法，可以看到有一行 `Globals.program.simulateFromPC(breakPoints, maxSteps, this);` 这里面的 `Globals.program` 为 `MIPSProgram` 类。
-  `mars.MIPSProgram` ：代表汇编程序。
  - 刚才进入的 `simulateFromPC` 方法内找到了 `RegisterFile` 类，此类为寄存器文件（寄存器堆），位于 `mars.mips.hardware` 。
-  `mars.mips.hardware` 包：此包与CPU中的硬件/部件有关的类。
  -  `RegisterFile` ： 寄存器文件/寄存器堆。
  -  `Register` ：代表 `RegisterFile` 中的一个寄存器。**写寄存器的输出信息在此或者在 `RegisterFile` 中添加**。
  -  `Memory` ：代表内存。**写内存的输出信息在此添加**。
  -  `MemoryConfigurations` ：内存地址的配置类（整体）。
  -  `MemoryConfiguration` ：这个类代表内存地址配置的其中一条（一共有 3 种选项）。
-  `mars.mips.instructions` ：此包包含与汇编指令集有关的类。
  -  `Instruction` ：代表一条汇编指令。
  -  `BasicInstruction` ：代表一条基本汇编指令（即不是扩展指令）
  -  `InstructionSet` ：汇编指令集。
  -  `syscalls` 包：涉及到 syscall 的类，在此包中可找到与输入输出有关的 syscall （例如 1 号 print integer ），打开其源代码可找到 Mars 中用于输出运行信息的 `SystemIO` 类。
-  `mars.Globals` ：一些全局共享的实例。
-  `mars.Settings` ：设置类，该类中存放 Mars 的各种设置选项。**内存配置应在此处修改**。
-  `mars.util.SystemIO` ：用于输入输出，利用此类提供的接口可自动根据是否启动图形界面来判断输出到命令行中还是图形界面的输出区中。

