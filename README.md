# 运行方式

1. 依赖：perl 5
2. 将.v文件添加进file_list
3. 执行prompt> perl main.pl

# 前言

本项目在[wxkhturf/AlignVerilog: To align *.v files. (github.com)](https://github.com/wxkhturf/AlignVerilog)的基础进行修改，主要检测以下两种ERROR：

1. `always`块中，当为时序逻辑时，却出现`=`阻塞赋值
2. `always`块中，当为组合逻辑时，却出现`<=`非阻塞赋值

## 过程

1. 删除注释

2. 删除module头

3. 删除空白行

4. 所有`always`字样前一行，加上一空白行（作为下一个`always`分隔）

5. 按空白行对always进行分割判断：如果含`posedge/negedge`就判断里面是`=`还是`<=`

   >判断时序：如果检测到`posedge/negedge`则认为该`always`块是时序逻辑，否则就认为是组合逻辑

6. 如果检测到错误，才在temp文件夹中创建同名文件，并将错误的always块写入进去，否则不创建文件

7. <u>本项目只用于检测，最后需要人为在temp文件夹中进行视检！！！</u>

