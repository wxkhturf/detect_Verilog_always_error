#!/usr/bin/perl -w
use strict;

use Cwd qw( getcwd abs_path);
my $path = abs_path(getcwd()); 
require $path."/module.pm";
require $path."/note.pm";
require $path."/assign.pm";
require $path."/decl.pm";
require $path."/block.pm";
require $path."/symbol.pm";



open(FILEIN,"<./file_list.f");
my @all_files = <FILEIN>;
close FILEIN;

system ("mkdir -p temp");

foreach $a (@all_files)
{
    open (FILETEMP,"< $a");
    my @lines = <FILETEMP>;
    close FILETEMP;
    #add user function***************************************************

    my @cont;
    my %note_parall;
    #将"/**/"型注释单独搞成几行:即"/*"置于行首,"*/"后直接就是换行符
    @cont = note::wrap_note(@lines);
    #将"module"块的"module"字样置于行首
    @cont = module::head_module(@cont);

    #将"/**/"型注释剪切到哈希中
    my %note_2      = note::cut_note2('2',@cont);
    @cont           = note::cut_note2('1',@cont);
    
    #将"//"型注释剪切到哈希中
    my %note_1  = note::cut_note1('2',@cont);
    @cont    = note::cut_note1('1',@cont);


    #将Tab键转换为空格
    @cont = note::tab_space_convert(@cont);

    #开始检测并对齐
    @cont = detect_always_error(@cont);


    
    #add user function**********************************************
    #仅当@cont非空时（说明检测到Error），再创建文件并写入
    if(@cont){
        open(FILEOUT,"> ./temp/$a");
        foreach (@cont){
            print FILEOUT $_;
        }
    }
    close FILEOUT;
}

#主体检测并对齐
sub detect_always_error{
    my @lines = @_;
    my @new_lines;
    my @output;
    my $const_cnt;
    my $cnt = 0;
    my $end_cnt;
    my @result;
    #第1个while：
    # 1. 删除注释
    # 2. 删除module头
    # 3. 删除空白行
    # 4. 所有always字样前一行，加上一空白行
    # 5. 按空白行对always进行分割判断：如果含posedge/negedge就判断里面是=还是<=
    while($cnt < scalar(@lines)){
        my $line = $lines[$cnt];
        if($line =~ /^\s*$/){
            #删除空白行
            #push(@new_lines,$line);
        } elsif($line =~ /\s*module[\s\(]+/){
            #删除module块
            while($cnt < scalar(@lines)){
                $line = $lines[$cnt];
                if($line =~/;/){
                    last;
                }
                $cnt ++;
            }
        } elsif ( $line =~ /^\s*assign\s+/){
            #删除assign语句
            while($cnt < scalar(@lines)){
                $line = $lines[$cnt];
                if($line =~/;/){
                    last;
                }
                $cnt ++;
            }
        } elsif( $line =~ /^\s*$symbol::DECL_REGEX(\s+|\[)/){
            #删除变量声明语句
            ($cnt,@result) = declaration::align_decl($cnt,@lines);
            #@new_lines = (@new_lines,@result);    
        } elsif($line =~ /^\s*always(\s*|@|#|\()/){
            #在所有的alwasys块前加上一空行
            ($cnt,@result) = block::align_block($cnt,@lines);
            push(@new_lines, "\n");
            @new_lines = (@new_lines,@result);    
        } elsif($line =~ /^\s*endmodule\s+/){
            #保留endmodule
            $line =~ s/^\s+//g ;
            push(@new_lines,$line);
        } else {
            push(@new_lines,$line);
        }
        $cnt ++;
    }

    #第2个while：检测出可疑的alwasy块
    $cnt = 0;
    my @tmp_store;
    my $error_detect = 0;
    my $is_clk = 0;
    while($cnt < scalar(@new_lines)){
        my $line = $new_lines[$cnt];
        $error_detect = 0;
        $is_clk = 0;
        #置位error_detect
        $error_detect = 0;
        #清空数组
        @tmp_store = ();
        if($line =~ /^\s*always(\s*|@|#|\()/){
            #检测是否包含posedge 或 negedge
            if($line =~ /\(\s*(?:posedge|negedge)\s+/){
                $is_clk = 1;
            } else {
                $is_clk = 0;
            }

            while($cnt < scalar(@new_lines)){
                $line = $new_lines[$cnt];
                if($is_clk == 1){
                    #如果检测到阻塞赋值，说明有error
                    #要匹配单独的等号 =，而排除 <=、==、!=、>=、=~、^=、===、!==
                    $error_detect = 1 if($line =~ /^(?!=)(?<!<=)(?<!==)(?<!!=)(?<!>=)(?!=~)(?<!\^=)(?<!===)(?<!!==)=/);
                } else {
                    #如果检测到非阻塞赋值，说明有error
                    $error_detect = 1 if($line =~ /<=/);
                }
                push(@tmp_store, $line);
                if($line =~ /^\s*$/){
                    #检测到空白行，说明新的always块要开始了
                    #本次检测结束
                    last;
                }
                $cnt ++;
            }
        }
        if($error_detect == 1){
            @output = (@output, @tmp_store);
        }
        $cnt ++;
    }
    return @output;
}

1;

            