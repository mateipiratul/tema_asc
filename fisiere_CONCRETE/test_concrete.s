.data
    formatString: .asciz "%s"
    descLabel: .asciz "File Descriptor: %d\n"
    sizeLabel: .asciz "File Size: %d kilobytes\n\n"
    afis_nr: .asciz "%d \n"

    # Buffers and variables
    path: .space 256
    dirPtr: .space 4 # pointer to DIR structure
    dirEntryPtr: .space 4 # pointer to dirent structure

.text
CONCRETE:
    pushl %ebp
    movl %esp, %ebp

    leal path, %edi # address of the path buffer
    pushl %edi
    call opendir
    addl $4, %esp
    movl %eax, dirPtr

read_dir:
    movl dirPtr, %edi
    pushl %edi
    call readdir
    addl $4, %esp
    testl %eax, %eax # check if null
    je close_dir
    movl %eax, dirEntryPtr # save dirent* pointer

    # get the d_name field of dirent
    movl dirEntryPtr, %edi
    addl $11, %edi # address of d_name in dirent

    pushl %edi # open the file using d_name
    call open
    addl $4, %esp
    movl %eax, %ebx # save file descriptor


    pushl %ebx # print file descriptor
    pushl $descLabel
    call printf
    addl $8, %esp

    # get file size with lseek
    movl $19, %eax
    movl %ebx, %edi # file descriptor
    xorl %ecx, %ecx # offset
    movl $2, %edx # SEEK_END
    int $0x80
    movl %eax, %ecx # save file size

    addl $1023, %ecx # calculate file size in kilobytes
    shrl $10, %ecx # divide by 1024

    pushl %ecx # print file size
    pushl $sizeLabel
    call printf
    addl $8, %esp

    jmp read_dir

close_dir:
    movl dirPtr, %edi
    pushl %edi
    call closedir
    addl $4, %esp

exit_CONCRETE:
    popl %ebp
    ret

.global main
main:
    pushl $path
    pushl $formatString
    call scanf
    addl $8, %esp

    call CONCRETE

    movl $1, %eax
    xorl %ebx, %ebx
    int $0x80