OPCODE_LENGTH = 4
SYMBOL_LENGTH = 32
BID_PX_LENGTH = 64
BID_SIZE_LENGTH = 8
OFFER_PX_LENGTH = 64
OFFER_SIZE_LENGTH = 8

# Function to convert a decimal number to binary string of a specific length
def decimal_to_binary(value, length):
    binary_str = format(value, 'b')
    return binary_str.zfill(length)

# Function to generate a data packet
def generate_data_packet(price, quantity, buy_sell, confirm):
    symbol = "00100011011101011011101011011000"
    if buy_sell == 1:
        bid_px = decimal_to_binary(0, BID_PX_LENGTH)
        bid_size = decimal_to_binary(0, BID_SIZE_LENGTH)
        offer_px = decimal_to_binary(price, OFFER_PX_LENGTH)
        offer_size = decimal_to_binary(quantity, OFFER_SIZE_LENGTH)
        if confirm:
            msg_type = '11'
        else:
            msg_type = '01'
    else:
        bid_px = decimal_to_binary(price, BID_PX_LENGTH)
        bid_size = decimal_to_binary(quantity, BID_SIZE_LENGTH)
        offer_px = decimal_to_binary(0, OFFER_PX_LENGTH)
        offer_size = decimal_to_binary(0, OFFER_SIZE_LENGTH)
        if confirm:
            msg_type = '11'
        else:
            msg_type = '10'
    # Insert underscores after each field
    data = f"{msg_type}{symbol}{bid_px}{bid_size}{offer_px}{offer_size}"
    return data

def split_into_chunks(binary_string, chunk_size):
    # Calculate the number of bits needed to pad
    padding = chunk_size - (len(binary_string) % chunk_size)
    # Pad the binary string with zeros
    binary_string = binary_string.zfill(len(binary_string) + padding)
    chunks = []
    while binary_string:
        # Take chunk_size bits from the right end of the binary string
        chunk = binary_string[-chunk_size:]
        # Remove the taken bits from the binary string
        binary_string = binary_string[:-chunk_size]
        # Prepend the chunk to the list of chunks
        chunks.insert(0, chunk)
    return chunks

def create_trace_file(filename, transactions, sma_length=4, threshold=0.01):
    total_purchased = 0

    # Compute the static SMA based on the first sma_length transactions
    sma_prices = [t[0] for t in transactions[:sma_length]]
    sma = sum(sma_prices) / 4 #len(sma_prices)

    with open(filename, 'w') as file:
        for i, (price, quantity, buy_sell) in enumerate(transactions):

            if buy_sell == 0:
                # Sell Operation
                packet = generate_data_packet(price, quantity, buy_sell, 0)
                split = split_into_chunks(packet, 75)
                file.write(f"  # Sell {price} {quantity}" + "\n")
                file.write(f"0001____0_{split[2]}" + "\n")  # Send
                file.write(f"0001____0_{split[1]}" + "\n")  # Send
                file.write(f"0001____0_{split[0]}" + "\n" + "\n")  # Send

                recv_packet = generate_data_packet(price, quantity, 1, 0)
                split_recv = split_into_chunks(recv_packet, 75)

                confirm_packet = generate_data_packet(price, quantity, 1, 1)
                split_confirm = split_into_chunks(confirm_packet, 75)

                if price < (sma - 20): #* (1 - threshold):
                    file.write(f"0010____0_{split_recv[2]}" + "\n")  # Receive Packet (checking output)
                    file.write(f"0010____0_{split_recv[1]}" + "\n")  # Receive Packet
                    file.write(f"0010____0_{split_recv[0]}" + "\n" + "\n")  # Receive Packet

                    file.write(f"0001____0_{split_confirm[2]}" + "\n")  # Confirm Packet
                    file.write(f"0001____0_{split_confirm[1]}" + "\n")  # Confirm Packet
                    file.write(f"0001____0_{split_confirm[0]}" + "\n" + "\n")  # Confirm Packet

                    total_purchased += quantity
                file.write(f"0010____0_" + '0' * 75 + "\n" )
                file.write(f"0010____0_" + '0' * 75 + "\n" )
                file.write(f"0010____0_" + '0' * 75 + "\n" + "\n" )
            else:
                # Buy Operation
                packet = generate_data_packet(price, quantity, buy_sell, 0)
                split = split_into_chunks(packet, 75)
                file.write(f"  # BUY {price} {quantity}" + "\n")
                file.write(f"0001____0_{split[2]}" + "\n")  # Send
                file.write(f"0001____0_{split[1]}" + "\n")  # Send
                file.write(f"0001____0_{split[0]}" + "\n" + "\n")  # Send

                if ((price > sma + 20) and (total_purchased != 0)): #(price > sma * (1 + threshold)) and (total_purchased != 0):
                    if total_purchased >= quantity:
                        recv_packet = generate_data_packet(price, quantity, 0, 0)
                        split_recv = split_into_chunks(recv_packet, 75)
                        file.write(f"0010____0_{split_recv[2]}" + "\n")  # Receive Packet (checking output)
                        file.write(f"0010____0_{split_recv[1]}" + "\n")  # Receive Packet
                        file.write(f"0010____0_{split_recv[0]}" + "\n" + "\n")  # Receive Packet

                        total_purchased -= quantity

                        confirm_packet = generate_data_packet(price, quantity, 0, 1)
                        split_confirm = split_into_chunks(confirm_packet, 75)
                        file.write(f"0001____0_{split_confirm[2]}" + "\n")  # Confirm Packet
                        file.write(f"0001____0_{split_confirm[1]}" + "\n")  # Confirm Packet
                        file.write(f"0001____0_{split_confirm[0]}" + "\n" + "\n")  # Confirm Packet

                    else:
                        recv_packet = generate_data_packet(price, total_purchased, 0, 0)
                        split_recv = split_into_chunks(recv_packet, 75)
                        file.write(f"0010____0_{split_recv[2]}" + "\n")  # Receive Packet (checking output)
                        file.write(f"0010____0_{split_recv[1]}" + "\n")  # Receive Packet
                        file.write(f"0010____0_{split_recv[0]}" + "\n" + "\n")  # Receive Packet

                        confirm_packet = generate_data_packet(price, total_purchased, 0, 1)
                        split_confirm = split_into_chunks(confirm_packet, 75)
                        file.write(f"0001____0_{split_confirm[2]}" + "\n")  # Confirm Packet
                        file.write(f"0001____0_{split_confirm[1]}" + "\n")  # Confirm Packet
                        file.write(f"0001____0_{split_confirm[0]}" + "\n" + "\n")  # Confirm Packet

                        total_purchased = 0
                file.write(f"0010____0_" + '0' * 75 + "\n" )
                file.write(f"0010____0_" + '0' * 75 + "\n" )
                file.write(f"0010____0_" + '0' * 75 + "\n" + "\n" )
        # Done operation
        file.write("\n")
        file.write("#" * 10 + "SIMULATION FINISHED" + "#" * 10 + "\n")
        file.write(f"0011____0_{decimal_to_binary(0, 75)}\n")

# Main function to run the simulation
def run_simulation():
    filename = "bsg_trace_master_0.tr"

    # (price, quantity, buy_sell) buy = 1 sell = 0
    transactions = [
        (10125, 10, 1),  # Buy 10 at 10125
        (9979, 5, 0),   # Sell 5 at 10150
        (9979, 20, 1),  # Buy 20 at 10275
        (15300, 15, 0),  # Sell 15 at 15300
        (10425, 8, 1),   # Buy 8 at 10425
        (10550, 12, 0),  # Sell 12 at 10550
        (10675, 25, 1),  # Buy 25 at 10675
        (10700, 10, 0),  # Sell 10 at 10700
        (10825, 30, 1),  # Buy 30 at 10825
        (10950, 20, 0),  # Sell 20 at 10950
        (20075, 40, 1),  # Buy 40 at 20075
        (11100, 10, 0),  # Sell 10 at 11100
        (11225, 35, 1),  # Buy 35 at 11225
        (11350, 15, 0),  # Sell 15 at 11350
        (11475, 50, 1),  # Buy 50 at 11475
        (11625, 45, 1),  # Buy 45 at 11625
        (11750, 25, 0),  # Sell 25 at 11750
        (11875, 60, 1),  # Buy 60 at 11875
        (11900, 30, 0),  # Sell 30 at 11900
    ]
    create_trace_file(filename, transactions)
    print(f"Trace file {filename} created.")

# Run the simulation
run_simulation()
