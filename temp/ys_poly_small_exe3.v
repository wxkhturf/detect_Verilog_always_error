always@(posedge clk or negedge rst_n) 
    begin           
        if (!rst_n) 
            begin
                functions  =  2'b0  ;   parameters  <=  2'b0  ; 
            end
        else if (start_poly) 
            begin
                functions  <=  ins [4 : 3]   ;   parameters  <=  ins [2 : 1]   ; 
            end
        else  
        begin 
            functions  <=  functions  ;  parameters  <=  parameters  ; 
        end
    end

