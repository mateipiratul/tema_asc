.data
    formatString: .asciz "%s"
    nameLabel: .asciz "File name: %s\n"
    descLabel: .asciz "File Descriptor: %d\n"
    sizeLabel: .asciz "File Size: %ld kilobytes\n\n"
    afis_nr: .asciz "%d \n"

    # Buffers and variables
    path: .space 256
    dirFd: .space 4
    dirPtr: .space 4 # pointer to DIR structure
    dirEntryPtr: .space 4 # pointer to dirent structure

.text
CONCRETE:
    pushl %ebp
    movl %esp, %ebp

    leal path, %edi
    pushl %edi
    call opendir
    addl $4, %esp
    movl %eax, dirPtr

    movl dirPtr, %edi
    pushl %edi
    call dirfd
    addl $4, %esp
    movl %eax, dirFd

read_dir:
    movl dirPtr, %edi
    pushl %edi
    call readdir
    addl $4, %esp
    testl %eax, %eax
    je close_dir
    movl %eax, dirEntryPtr

    # get the d_name field of dirent
    movl dirEntryPtr, %edi
    addl $11, %edi # address of d_name in dirent

    movl $46, %eax
    cmpl %eax, (%edi)
    je read_dir
    cmpl %eax, 1(%edi)
    je read_dir

    pushl %edi
    pushl $nameLabel
    call printf
    addl $8, %esp

    movl dirFd, %eax
    pushl %edi
    pushl %eax
    call openat
    addl $8, %esp
    movl %eax, %ebx

    pushl %ebx
    pushl $descLabel
    call printf
    addl $8, %esp

    # lseek function
    pushl $2           # SEEK_END
    pushl $0           # Offset
    pushl %ebx         # File descriptor
    call lseek
    addl $12, %esp
    movl %eax, %ecx    # File size in bytes

    addl $1023, %ecx
    shrl $10, %ecx

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