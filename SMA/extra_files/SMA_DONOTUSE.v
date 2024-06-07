module SMA (input new_data,
            output [17:0] average); 
            //inputs from Data FIFO, outputs to trading logic 
            //does new data come in at 18 bit or does it need to be converted?
    logic book_avg, book_sum, num_i, i, valid_bit;
    logic [17:0] last_data;

    logic [17:0] data_book [0:63]; //Array stores 256 instances of 18 bit data
    
    //need some way to assign valid data, valid bit?
    if new_data == last_data:
        valid_bit = 0;
    else
        valid_bit = 1;
    
    //counter = 

    // initial begin
    //     for ( i=0; i < counter; i++) begin
    //         data_book[i] = new_data; 
    //         //Idea: Stores each new value in the data book
    //         //Execution: 
    //     end
    // end


    //use case statements
    //case()
    //
    //endcase

    if line_length(stock_book) < 11:
    
    if stock_book < 11:
        for (i in line_length(stock_book)):begin
            last_book = stock_book[i]
            book_sum = book_sum + i;
            num_i = num_i + i;
            book_avg = book_sum / num_i;
            end
    else:
        last_book = stock_book[10] //11th entry
        book_sum = book_sum + new_book - last_book
        book_avg = book_sum / 10;



endmodule

//or case statements? Priority case? Have seperate bits to indicate ready, new data, data shift.
//FIFO filter? Automatically only holds onto 10 values, spits out last/gets overwritten.

//need some way to call this module
//upon calling, update last_book, book_avg, book_sum
//assumes stock_book will be updated where index[0] is most recent entry