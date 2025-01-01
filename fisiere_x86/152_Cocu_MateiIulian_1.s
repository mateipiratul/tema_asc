.data
    O: .space 4 # nr. operatii total
    operat: .space 4 # indicele operatiei
    N: .space 4 # nr. op. ADD
    ID: .space 4 # data citire
    sizeKB: .space 4 # data citire ADD
    indX: .space 4 # data afisare startX, endX
    startY: .space 4 # data afisare startY
    endY: .space 4 # data afisare endY
    fileID: .space 4 # pentru procedura de afisare
    ind: .space 4 # loop main pentru apel proceduri
    blocuri: .space 4 # variabila pentru ADD
    blocuri_defrag: .space 4
    lowBound: .space 4 # (0, 1024, ...)
    highBound: .space 4 # (1024, 2048, ...)
    # highBound are o exceptie pentru ADD (1025, 2049, ...)
    fd: .space 4 # DEFRAG ID_fisier
    fSize: .space 4 # DEFRAG marime_fisier
    row: .space 4 # DEFRAG var
    dirFd: .space 4
    dirPtr: .space 4 # pointer to DIR structure
    dirEntryPtr: .space 4 # pointer to dirent structure
    contCRETE: .long 0 # contor pana la 256
    formatString: .asciz "%s"
    citire: .asciz "%d"
    afisare_ADD_DEL_DEFRAG: .asciz "%d: ((%d, %d), (%d, %d))\n"
    afisare_GET: .asciz "((%d, %d), (%d, %d))\n"
    path: .space 128 # absolute path given as input for CONCRETE
    mat:
        .rept 1048576
        .long 0
        .endr
.text
ADD:
    pushl %ebx
    pushl %edi
    pushl %ebp
    movl %esp, %ebp # stack frame reset

    movl sizeKB, %eax # EAX = sizeKB
    addl $7, %eax
    shrl $3, %eax # EAX = blocksNeeded

    cmpl $1024, %eax # daca fisierul este prea mare
    jg alloc_fail # acesta nu va putea fi adaugat

    leal mat, %edi
    movl $0, lowBound
    movl $1025, highBound
    loop_rows:
        movl lowBound, %ecx
        cmpl $1048576, %ecx
        je alloc_fail

        movl highBound, %ebx
        subl %eax, %ebx # EBX = highBound - blocksNeeded
        movl %ecx, %edx # EDX = index principal coloane

        loop_search_gap:
            cmpl %ebx, %edx # daca EDX ajunge la sfarsitul randului
            je finish_loop_rows # se trece la urmatorul rand
            
            movl %edx, %esi # trecem la bucla secundara
            movl %edx, blocuri
            addl %eax, blocuri
            check_gap: # verifica daca exista initial spatiul necesar
                cmpl %esi, blocuri
                je fill_gap
                
                movl (%edi, %esi, 4), %ecx
                cmpl $0, %ecx
                jne search_next

                incl %esi
                jmp check_gap

            fill_gap:
                movl %edx, %esi
                loop_fill:
                    cmpl %esi, blocuri
                    je set_output

                    pushl %ecx
                    movl ID, %ecx
                    movl %ecx, (%edi, %esi, 4)
                    incl %esi
                    popl %ecx
                    jmp loop_fill

            search_next:
                incl %edx
                jmp loop_search_gap
            finish_loop_rows:
                addl $1024, lowBound
                addl $1024, highBound
                jmp loop_rows

    set_output:
        movl lowBound, %eax
        movl %edx, startY
        subl %eax, startY
        movl %esi, endY
        subl %eax, endY
        decl endY
        xorl %edx, %edx
        movl $1024, %ebx
        divl %ebx
        movl %eax, indX
        jmp exit_ADD

    alloc_fail:
        movl $0, indX
        movl $0, startY
        movl $0, endY
        jmp exit_ADD

    exit_ADD:
        popl %ebp
        popl %edi
        popl %ebx
        ret

GET:
    pushl %ebx
    pushl %edi
    pushl %ebp
    movl %esp, %ebp # stack frame reset

    pushl $ID # citire ID
    pushl $citire
    call scanf
    addl $8, %esp

    movl $0, lowBound
    movl $1024, highBound
    xorl %ecx, %ecx
    leal mat, %edi

    for_rows:
        movl lowBound, %ecx
        cmpl $1048576, %ecx
        je not_found

        movl %ecx, %esi # ESI = indexul coloanei
        while_search:
            cmpl highBound, %esi # daca nu a fost gasit pe linia respectiva
            je finish_for_rows # se trece la urmatoarea

            movl (%edi, %esi, 4), %eax
            cmpl ID, %eax
            je found_ID

            incl %esi
            jmp while_search

        found_ID:
            # folosim EBX ca registru intermediar 
            movl lowBound, %eax # calculam rezultatul indX
            movl $1024, %ebx
            xorl %edx, %edx
            divl %ebx # EAX = indX (lowBound / 1024)
            movl %eax, indX # indX a fost calculat
            movl %esi, %ebx # se calculeaza startY
            subl lowBound, %ebx # EBX = startY
            movl %ebx, startY # a fost calculat startY
            movl (%edi, %esi, 4), %eax # EAX = mat[%esi]

            while_found:
                cmpl ID, %eax # daca nu mai este identificat ID-ul
                jne set_output_GET # ESI = endY + 1

                incl %esi
                movl (%edi, %esi, 4), %eax
                jmp while_found

        finish_for_rows:
            addl $1024, lowBound
            addl $1024, highBound
            jmp for_rows
    
    not_found:
        movl $0, indX
        movl $0, startY
        movl $0, endY
        jmp afis
    set_output_GET:
        decl %esi # rectificare endY
        subl lowBound, %esi
        movl %esi, endY
        jmp afis
    
    afis:
        pushl endY # se afiseaza raspunsul
        pushl indX
        pushl startY
        pushl indX
        pushl $afisare_GET
        call printf
        addl $20, %esp

    popl %ebp
    popl %edi
    popl %ebx
    ret

DEL:
    pushl %ebx
    pushl %edi
    pushl %ebp
    movl %esp, %ebp # reset stack frame

    pushl $ID # citire ID
    pushl $citire
    call scanf
    addl $8, %esp

    movl $0, lowBound
    movl $1024, highBound
    xorl %ecx, %ecx
    leal mat, %edi
    
    parc_linii:
        movl lowBound, %ecx
        cmpl $1048576, %ecx
        je exit_DEL
    
        movl %ecx, %esi # ESI = indexul coloanei
        cautare_ID:
            cmpl highBound, %esi # daca nu a fost gasit pe linie ID
            je final_parc_linii # se trece la urmatoarea

            movl (%edi, %esi, 4), %eax
            cmpl ID, %eax
            je proc_stergere

            incl %esi
            jmp cautare_ID
        
        proc_stergere:
            cmpl ID, %eax # daca nu mai apare ID
            jne exit_DEL # inseamna ca am terminat de sters ce trebuia

            movl $0, (%edi, %esi, 4) # mat[%esi] = 0
            incl %esi
            movl (%edi, %esi, 4), %eax
            jmp proc_stergere

        final_parc_linii:
            addl $1024, lowBound
            addl $1024, highBound
            jmp parc_linii
    
    exit_DEL:
        popl %ebp
        popl %edi
        popl %ebx
        ret

DEFRAG:
    pushl %ebx
    pushl %edi
    pushl %ebp
    movl %esp, %ebp # reset stack frame

    movl $0, row
    movl $0, lowBound
    movl $1024, highBound
    leal mat, %edi

    for_linii:
        movl lowBound, %ecx
        cmpl $1048576, %ecx
        je exit_DEFRAG

        movl %ecx, %esi
        movl %ecx, %edx
        for_coloane:
            cmpl highBound, %esi
            je final_for_linii

            movl (%edi, %esi, 4), %eax
            cmpl $0, %eax
            je final_for_coloane

            movl %eax, fd
            xorl %ebx, %ebx

                final_while_col:
                    movl %ebx, fSize
                    decl %esi
                    pushl %eax
                    pushl %ecx
                    pushl %edx
                    call DEL_defrag
                    call ADD_defrag
                    popl %edx
                    popl %ecx
                    popl %eax

            final_for_coloane:
                incl %esi
                jmp for_coloane

        final_for_linii:
            addl $1024, lowBound
            addl $1024, highBound
            jmp for_linii
    
    exit_DEFRAG:
        popl %ebp
        popl %edi
        popl %ebx
        ret

DEL_defrag:
    pushl %ebx
    pushl %edi
    pushl %ebp
    movl %esp, %ebp # reset stack frame

    movl $0, lowBound
    movl $1024, highBound
    xorl %ecx, %ecx
    leal mat, %edi
    movl $0, fSize

    parc_linii_defrag:
        movl lowBound, %ecx
        cmpl $1048576, %ecx
        je exit_DEL_defrag
    
        movl %ecx, %esi # ESI = indexul coloanei
        cautare_ID_defrag:
            cmpl highBound, %esi # daca nu a fost gasit pe linie ID
            je final_parc_linii_defrag # se trece la urmatoarea

            movl (%edi, %esi, 4), %eax
            cmpl fd, %eax
            je proc_stergere_defrag

            incl %esi
            jmp cautare_ID_defrag
        
        proc_stergere_defrag:
            cmpl fd, %eax # daca nu mai apare ID
            jne exit_DEL_defrag # inseamna ca am terminat de sters ce trebuia

            movl $0, (%edi, %esi, 4) # mat[%esi] = 0
            incl fSize
            incl %esi
            movl (%edi, %esi, 4), %eax
            jmp proc_stergere_defrag

        final_parc_linii_defrag:
            addl $1024, lowBound
            addl $1024, highBound
            jmp parc_linii_defrag
    
    exit_DEL_defrag:
        popl %ebp
        popl %edi
        popl %ebx
        ret

ADD_defrag:
    pushl %ebx
    pushl %edi
    pushl %ebp
    movl %esp, %ebp # stack frame reset

    movl fSize, %eax
    leal mat, %edi
    movl row, %ebx
    movl %ebx, lowBound
    addl $1025, %ebx
    movl %ebx, highBound
    loop_rows_defrag:
        movl row, %ecx
        cmpl $1048576, %ecx
        jge exit_ADD_defrag

        subl %eax, %ebx # EBX = highBound - blocksNeeded
        movl %ecx, %edx # EDX = index principal coloane

        loop_search_gap_defrag:
            cmpl %ebx, %edx # daca EDX ajunge la sfarsitul randului
            je finish_loop_rows_defrag # se trece la urmatorul rand
            
            movl %edx, %esi # trecem la bucla secundara
            movl %edx, fSize
            addl %eax, fSize
            check_gap_defrag: # verifica daca exista initial spatiul necesar
                cmpl %esi, fSize
                je fill_gap_defrag
                
                movl (%edi, %esi, 4), %ecx
                cmpl $0, %ecx
                jne search_next_defrag

                incl %esi
                jmp check_gap_defrag

            fill_gap_defrag:
                movl %edx, %esi
                loop_fill_defrag:
                    cmpl %esi, fSize
                    je exit_ADD_defrag

                    pushl %ecx
                    movl fd, %ecx
                    movl %ecx, (%edi, %esi, 4)
                    incl %esi
                    popl %ecx
                    jmp loop_fill_defrag

            search_next_defrag:
                incl %edx
                jmp loop_search_gap_defrag
            finish_loop_rows_defrag:
                addl $1024, row
                addl $1024, highBound
                jmp loop_rows_defrag

    exit_ADD_defrag:
        popl %ebp
        popl %edi
        popl %ebx
        ret

printing_DEL_DEFRAG: # procedura de afisare
    pushl %ebx
    pushl %edi
    pushl %ebp
    movl %esp, %ebp # reset stack frame

    leal mat, %edi
    xorl %ecx, %ecx # index reset
    loop_printing_DEL_DEFRAG:
        cmpl $1048576, %ecx # daca am trecut prin toata "matricea"
        je exit_PRINTING # iesim din procedura de afisare
        movl (%edi, %ecx, 4), %ebx
        cmpl $0, %ebx # daca nu exista ID
        je skip # trecem la urmatoarea pozitie, nu afisam nimic
        
        movl %ebx, fileID # fileID retine valoarea ID, pentru afisare
        xorl %edx, %edx # calculam indX
        movl $1024, %esi
        movl %ecx, %eax # EAX = pozitia in "matrice" 
        divl %esi # EAX = indX, EDX = startY
        movl %eax, indX
        movl %edx, startY

        while_endY:
            cmpl fileID, %ebx # daca am "iesit" din fisier
            jne scapare # se trece la afisare
            incl %ecx
            movl (%edi, %ecx, 4), %ebx
            jmp while_endY

        scapare:
            decl %ecx
            movl %ecx, %eax # se calculeaza endY/= 1024;
            xorl %edx, %edx
            movl $1024, %esi
            divl %esi # EAX = endY
            movl %edx, endY
            pushl %eax
            pushl %ecx
            pushl %edi
            pushl endY
            pushl indX
            pushl startY
            pushl indX
            pushl fileID
            pushl $afisare_ADD_DEL_DEFRAG
            call printf
            addl $24, %esp
            popl %edi
            popl %ecx
            popl %eax
        
        skip:
            incl %ecx
            jmp loop_printing_DEL_DEFRAG

    exit_PRINTING:
        popl %ebp
        popl %edi
        popl %ebx
        ret

CONCRETE:
    pushl %ebp
    movl %esp, %ebp # reset stack frame

    pushl $path # citirea path-ului absolut
    pushl $formatString
    call scanf
    addl $8, %esp

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
        incl contCRETE
        movl %eax, dirEntryPtr

        # get the d_name field of dirent
        movl dirEntryPtr, %edi
        addl $11, %edi # address of d_name in dirent

        movl $46, %eax
        cmpl %eax, (%edi)
        je read_dir
        cmpl %eax, 1(%edi)
        je read_dir

        movl dirFd, %eax
        pushl %edi
        pushl %eax
        call openat
        addl $8, %esp
        movl %eax, ID

        cmpl $255, contCRETE
        jg afisNUL

        # lseek function
        pushl $2 # SEEK_END
        pushl $0 # offset
        pushl %eax # file descriptor
        call lseek
        addl $12, %esp
        movl %eax, %ecx # file size in bytes
        addl $1023, %ecx
        shrl $10, %ecx # file size in kilobytes
        movl %ecx, sizeKB

        # converting ID to required format
        movl ID, %eax
        movl $255, %ebx
        xorl %edx, %edx
        divl %ebx
        movl %edx, %eax
        incl %eax
        movl %eax, ID
        call ADD
        pushl endY
        pushl indX
        pushl startY
        pushl indX
        pushl ID
        pushl $afisare_ADD_DEL_DEFRAG
        call printf
        addl $24, %esp
        jmp read_dir

        afisNUL:
            movl $255, %ebx
            xorl %edx, %edx
            divl %ebx
            movl %edx, %eax
            incl %eax
            movl %eax, ID
            pushl $0
            pushl $0
            pushl $0
            pushl $0
            pushl ID
            pushl $afisare_ADD_DEL_DEFRAG
            call printf
            addl $24, %esp
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
    pushl $O # numarul de operatii executate
    pushl $citire
    call scanf
    addl $8, %esp

    movl $0, ind # indexul operatiilor

    loop_op:
        movl ind, %ecx
        cmp %ecx, O
        je etexit

        pushl $operat
        pushl $citire
        call scanf
        addl $8, %esp
        movl operat, %eax # indicele operatiei -> EAX

        cmp $1, %eax # ADD
        je main_ADD

        cmp $2, %eax # GET
        je main_GET

        cmp $3, %eax # DELETE
        je main_DEL

        cmp $4, %eax # DEFRAGMENTATION
        je main_DEFRAG

        cmp $5, %eax # CONCRETE
        je main_CONCRETE

        cmp $5, %eax # operatie invalida -> iesire din program
        jg etexit

        sfarsit_loop_op:
            incl ind
            jmp loop_op
main_ADD:
    pushl $N # numarul de operatii ADD
    pushl $citire
    call scanf
    addl $8, %esp

    movl N, %ebx
    xorl %ecx, %ecx
    loop_ADD_main:
        cmpl %ebx, %ecx # daca au fost efectuate apelurile
        je sfarsit_loop_op

        pushl %ecx
        pushl %eax
        pushl %edx

        pushl $ID # citire ID [0, 255]
        pushl $citire
        call scanf
        addl $8, %esp
        
        pushl $sizeKB # citire marime fisier
        pushl $citire
        call scanf
        addl $8, %esp

        call ADD
        pushl endY
        pushl indX
        pushl startY
        pushl indX
        pushl ID
        pushl $afisare_ADD_DEL_DEFRAG
        call printf
        addl $24, %esp
        popl %edx
        popl %eax
        popl %ecx

        incl %ecx
        jmp loop_ADD_main

main_GET:
    pushl %ecx
    pushl %eax
    pushl %edx
    call GET
    popl %edx
    popl %eax
    popl %ecx
    jmp sfarsit_loop_op

main_DEL:
    pushl %ecx
    pushl %eax
    pushl %edx
    call DEL
    call printing_DEL_DEFRAG
    popl %edx
    popl %eax
    popl %ecx
    jmp sfarsit_loop_op

main_DEFRAG:
    pushl %ecx
    pushl %eax
    pushl %edx
    call DEFRAG
    call printing_DEL_DEFRAG
    popl %edx
    popl %eax
    popl %ecx
    jmp sfarsit_loop_op

main_CONCRETE:
    pushl %ecx
    pushl %eax
    pushl %edx
    call CONCRETE
    popl %edx
    popl %eax
    popl %ecx
    jmp sfarsit_loop_op

etexit:
    pushl $0
    call fflush
    popl %eax
    movl $1, %eax
    xorl %ebx, %ebx
    int $0x80