.data
    tfn_prompt:    .asciz "Enter the TFN to check: "  # No newline
    valid_msg:     .asciz "Hooray! The TFN is valid!"  # Removed newline at the end
    invalid_msg:   .asciz "Invalid TFN: Checksum Failed"  # Removed newline at the end
    format_error:  .asciz "Invalid TFN: Format Incorrect"  # Removed newline at the end
    
    input_buffer:  .space 12   # To store up to 9 digits + newline + null terminator
    weights:       .word 1, 4, 3, 7, 5, 8, 6, 9, 10  # Weights for each TFN digit

.text
    .globl main
    
    
.macro print_string(%reg) # print string register
addi a7, zero, 4
add a0, zero, %reg
ecall
.end_macro

.macro print_stringl(%label) # print string from label
addi a7, zero, 4
la a0, %label
ecall
.end_macro

main:
    # Prompt user for input
    print_stringl(tfn_prompt)  # Using macro to print the prompt

    # Get input from the user
    la a0, input_buffer        # Store input in input_buffer
    addi a1, zero, 12          # Buffer size to capture input (12 bytes)
    addi a7, zero, 8           # Syscall to read string (syscall 8)
    ecall

    # Check if the input is exactly 9 digits (excluding newline)
    addi t0, zero, 9           # t0 = expected length (9 digits)
    la t1, input_buffer        # Point t1 to input_buffer
    addi t2, zero, 0           # t2 = counter for the number of digits

length_check:
    lb t3, 0(t1)               # Load each byte from input_buffer
    addi t4, zero, 10          # t4 = ASCII value for newline
    beq t3, t4, length_done    # If newline, end the check
    beqz t3, length_done       # If null terminator, end the check
    addi t2, t2, 1             # Increment counter
    addi t1, t1, 1             # Move to next byte
    blt t2, t0, length_check   # Loop until we've read all digits

length_done:
    bne t2, t0, format_incorrect # If not exactly 9 digits, jump to format error

    # Initialize variables for checksum calculation
    la t1, input_buffer  # Pointer to input_buffer
    la t2, weights       # Pointer to weights
    addi t3, zero, 0     # t3 will store the checksum sum
    addi t4, zero, 0     # Index for digits (0-8)
    addi t6, zero, 9     # Upper bound for loop (process 9 digits)

checksum_loop:
    lb t5, 0(t1)         # Load the digit as ASCII
    addi t0, zero, 10    # ASCII value for newline
    beq t5, t0, check_done  # Stop at newline
    beq t4, t6, check_done  # Stop after processing 9 digits
    addi t5, t5, -48     # Convert ASCII to integer (subtract '0')
    
    lw t0, 0(t2)         # Load the weight for the current digit
    
    mul t0, t5, t0       # Multiply digit by its weight
    add t3, t3, t0       # Add the result to checksum sum

    addi t1, t1, 1       # Move to next digit in input_buffer
    addi t2, t2, 4       # Move to next weight
    addi t4, t4, 1       # Increment index
    blt t4, t6, checksum_loop   # Repeat for all 9 digits

check_done:
    # Check if the sum is divisible by 11
    addi t0, zero, 11        # Divisor
    rem t1, t3, t0           # t1 = t3 % 11
    beqz t1, valid_tfn       # If remainder is 0, the TFN is valid

    # If invalid, jump to invalid_tfn
    b invalid_tfn

valid_tfn:
    print_stringl(valid_msg)  # Using macro to print valid TFN message
    b end

invalid_tfn:
    print_stringl(invalid_msg)  # Using macro to print invalid TFN message
    b end

format_incorrect:
    print_stringl(format_error)  # Using macro to print format error message

end:
    addi a7, zero, 10        # Syscall for exit (syscall 10)
    ecall