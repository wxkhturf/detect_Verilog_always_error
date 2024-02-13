my $line = " functions = 2'b0;  parameters <= 2'b0;)";
if($line =~ /(?<![<==])=(?!=)/){
    print("ok");
} else{
    print("no");
}
