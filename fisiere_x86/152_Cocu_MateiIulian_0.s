.data
    O: .space 4 # nr. operatii total
    operat: .space 4 #indicele operatiei
    N: .space 4 # nr. op. ADD
    ID: .space 4
    sizeKB: .space 4
    i: .space 4 # index principal
    j: .space 4 # index secundar
    starta: .space 4 
    enda: .space 4
    fileID: .space 4
    citire: .asciz "%d"
    afisare_ADD_DEL_DEFRAG: .asciz "%d: (%d, %d)\n"
    afisare_GET: .asciz "(%d, %d)\n"
    afisare_spatiere: .asciz "\n"
    v: 
        .rept 1000
        .long 0
        .endr
.text
ADD:
    pushl %ebx
    pushl %edi
    pushl %ebp
    mov %esp, %ebp # reset stack frame

    pushl $ID # citire ID [0, 255]
    pushl $citire
    call scanf
    add $8, %esp

    pushl $sizeKB # citire marime fisier
    pushl $citire
    call scanf
    add $8, %esp

    # blocksNeeded = sizeKB / 8 + (sizeKB % 8 != 0 ? 1 : 0)
    movl sizeKB, %eax
    xorl %edx, %edx
    movl $8, %ebx
    divl %ebx # EAX = sizeKB / 8, restul in EDX
    cmp $0, %edx
    je mul_8
    incl %eax
    mul_8:
        cmp $1000, %eax # daca se da ca input un fisier care ocupa mai mult de 1000 de block-uri
        jg alloc_fail # atunci nu se poate aloca, returnam cazul exceptie
        movl %eax, %ebx # EBX = blocksNeeded

        # suitable gap in array
        xorl %ecx, %ecx # ECX = index curent
        leal v, %edi
        movl $1000, %edx # EDX = marime maxima array

    loop_search_gap:
        cmpl %edx, %ecx
        je alloc_fail # daca ECX ajunge la 1000, nu se poate aloca fisierul

        movl %ecx, i # start index potential
        movl %ebx, %eax # blocksNeeded
        addl %ecx, %eax # enda = starta + blocksNeeded
        cmpl %edx, %eax
        je search_next

        # verificare gap
        xorl %esi, %esi # ESI = inner-loop index
    check_gap:
        movl (%edi, %ecx, 4), %eax
        cmpl $0, %eax
        jne search_next

        incl %ecx
        incl %esi
        cmpl %ebx, %esi
        je can_alloc
        jmp check_gap

    search_next:
        incl %ecx
        jmp loop_search_gap

    can_alloc:
        movl i, %ecx # start alocare la index i
        movl %ebx, %eax # blocuri de alocat
    loop_allocate:
        cmpl $0, %eax
        je set_output
        movl ID, %ebx
        movl %ebx, (%edi, %ecx, 4) # v[%ecx] = ID 
        incl %ecx
        decl %eax
        jmp loop_allocate

    set_output:
        movl i, %ebx
        movl %ebx, starta
        movl %ecx, enda
        decl enda
        jmp exit_ADD

    alloc_fail:
        xorl %ecx, %ecx
        movl %ecx, starta
        movl %ecx, enda

    exit_ADD:
        popl %ebp
        popl %edi
        popl %ebx
        ret

GET:
    pushl %ebx
    pushl %edi
    pushl %ebp
    movl %esp, %ebp # resetarea stivei

    pushl $ID # citire ID
    pushl $citire
    call scanf
    add $8, %esp

    xorl %ecx, %ecx
    leal v, %edi
    movl (%edi, %ecx, 4), %eax

    while_search:
        cmp ID, %eax # daca v[%ecx] = ID
        je found_GET  # determinam valorile start & end

        cmp $1000, %ecx # cazul ID invalid
        je not_found_GET # ID-ul nu a fost gasit

        incl %ecx # incrementarea contorului
        movl (%edi, %ecx, 4), %eax # EAX preia urmatoarea valoare din array
        jmp while_search
    
    found_GET:
        movl %ecx, starta
        while_found:
            cmp ID, %eax
            jne def_output_GET

            incl %ecx
            movl (%edi, %ecx, 4), %eax
            jmp while_found
        
        def_output_GET:
            decl %ecx
            movl %ecx, enda
            jmp print_GET

    not_found_GET:
        xorl %ecx, %ecx
        movl %ecx, starta
        movl %ecx, enda
        jmp print_GET
    
    print_GET:
        pushl enda # afisarea (starta, enda)
        pushl starta
        pushl $afisare_GET
        call printf
        add $12, %esp

    popl %ebp
    popl %edi
    popl %ebx
    ret

DEL:
    pushl %ebx
    pushl %edi
    pushl %ebp
    movl %esp, %ebp # resetarea stivei

    pushl $ID # citire ID
    pushl $citire
    call scanf
    add $8, %esp

    xorl %ecx, %ecx # resetarea contorului
    leal v, %edi
    movl (%edi, %ecx, 4), %eax # EAX = v[0]

    while_find_ID:
        cmp %eax, ID # daca a fost gasita secventa de blocuri cu ID
        je proc_loop_DEL # trecem la procedura de stergere

        cmp $1000, %ecx # daca nu, nu se sterge nimic
        je exit_DEL # si se trece direct la afisare

        incl %ecx
        movl (%edi, %ecx, 4), %eax # se trece la urmatoarea valoare din array-ul v
        jmp while_find_ID

    proc_loop_DEL: # procedura de stergere in sine
        cmp %eax, ID
        jne exit_DEL

        movl $0, (%edi, %ecx, 4)
        incl %ecx
        movl (%edi, %ecx, 4), %eax
        jmp proc_loop_DEL

        exit_DEL:
            call printing_DEL_DEFRAG
            popl %ebp
            popl %edi
            popl %ebx
            ret

DEFRAG:
    pushl %ebx
    pushl %edi
    pushl %ebp
    movl %esp, %ebp # reset stack frame

    leal v, %edi
    xorl %ecx, %ecx # index
    movl (%edi, %ecx, 4), %eax # EAX = v[i]
    xorl %edx, %edx

    loop_assign:
        cmpl $1000, %ecx # daca indexul a ajuns la finalul vectorului
        je exit_DEFRAG
        cmpl $0, %eax # daca v[i] = 0
        je end_assign # atunci doar se incrementeaza indexul
        movl %eax, (%edi, %edx, 4)
        cmpl %edx, %ecx
        je skipper
        movl $0, (%edi, %ecx, 4)
        skipper:
            incl %edx
        end_assign:
            incl %ecx
            movl (%edi, %ecx, 4), %eax
            jmp loop_assign
    exit_DEFRAG:
        call printing_DEL_DEFRAG
        popl %ebp
        popl %edi
        popl %ebx
        ret

printing_DEL_DEFRAG: # procedura de afisare
    pushl %ebx
    pushl %edi
    pushl %ebp
    movl %esp, %ebp # reset stack frame
    xorl %ecx, %ecx
    movl (%edi, %ecx, 4), %eax
    loop_print_DEL_DEFRAG:
        cmpl $1000, %ecx # daca am trecut prin tot vectorul
        je exit_PRINTING # iesim din procedura de afisare
        cmpl $0, %eax # daca nu exista ID
        je skip # trecem la urmatoarea pozitie, nu afisam nimic
        movl %eax, %ebx
        movl %ecx, starta
        while_ENDA:
            cmp $1000, %ecx
            je scapare
            cmp %ebx, %eax
            jne scapare
            incl %ecx
            movl (%edi, %ecx, 4), %eax
            jmp while_ENDA            
            scapare:
                decl %ecx
                movl %ecx, enda
                pushl %eax
                pushl %ecx
                pushl %edi
                pushl enda
                pushl starta
                pushl %ebx
                pushl $afisare_ADD_DEL_DEFRAG
                call printf
                addl $16, %esp
                popl %edi
                popl %ecx
                popl %eax
            skip:
                incl %ecx
                movl (%edi, %ecx, 4), %eax
                jmp loop_print_DEL_DEFRAG
    exit_PRINTING:
        popl %ebp
        popl %edi
        popl %ebx
        ret

.global main
main:
    pushl $O # numarul de operatii executate
    pushl $citire
    call scanf
    addl $8, %esp

    movl $0, i # iterabil principal
    movl $0, j # iterabil secundar

    loop_op:
        movl j, %ecx
        cmp %ecx, O
        je etexit # au fost executate operatiile

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

        cmp $4, %eax # operatie invalida -> iesire din program
        jg etexit

        sfarsit_loop_op:
            pushl %eax
            pushl %ecx
            pushl $afisare_spatiere
            call printf
            add $4, %esp
            popl %ecx
            popl %eax
            incl j
            jmp loop_op
main_ADD:
    pushl $N # numarul de operatii ADD
    pushl $citire
    call scanf
    addl $8, %esp

    movl $0, i
    xorl %ecx, %ecx
    loop_ADD_main:
        movl N, %ebx
        cmpl %ebx, %ecx
        je sfarsit_loop_op

        pushl %ecx
        pushl %eax
        pushl %edx
        call ADD
        popl %edx
        popl %eax
        popl %ecx

        movl enda, %eax
        incl %eax
        movl %eax, i

        pushl %ecx
        pushl %eax
        pushl %edx
        pushl enda
        pushl starta
        pushl ID
        pushl $afisare_ADD_DEL_DEFRAG
        call printf
        add $16, %esp
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
    popl %edx
    popl %eax
    popl %ecx

    jmp sfarsit_loop_op

main_DEFRAG:
    pushl %ecx
    pushl %eax
    pushl %edx
    call DEFRAG
    popl %edx
    popl %eax
    popl %ecx

    jmp sfarsit_loop_op
etexit:
    movl $1, %eax
    xorl %ebx, %ebx
    int $0x80