time grep -r ".*" -H /c/v8/logs/*/*.log  | \
perl -ne '
    s/\xef\xbb\xbf//g;                              #BOM - обязательно в начале, иначе с певой строкой будут проблемы
    if(/\d\d:\d\d\.\d+-\d+,(\w+),/){                #если в строке есть идентификатор начала строки и это наш тип события
        if($1 eq "EXCP"){                           #первоначальный отбор по событиям            
            s/\s+/ /g;                              #сворачиваю много пробелов в один, и перенос строки тоже здесь улетит в пробел
            if(s/^.*_(\d+)\/(\d{2})(\d{2})(\d{2})(\d{2})\.log\:\s*(\d+:\d+\.\d+)\-(\d+),(\w+),(\d+)//){
                $_="\r\n"."dt=20".$2.".".$3.".".$4.",time=".$5.":".$6.",pid=".$1.",dur=".$7.",evnt=".$8.",ukn=".$9.$_ ;                
            }
            $f=1;
        }else{$f=0};
    }
    elsif($f) {                                     #если наше событие, то обрабатываем эту висячую  строку
        s/^.*log://;                                #из перенесённых строк просто вытираю начало
        s/\s+/ /g;                                  #сворачиваю много пробелов в один, и перенос строки тоже здесь улетит в пробел
    }
    if($f){
        s/\x27//g;                                  #убираю апострофы
        print $_;
    }END{print "\r\n"}                              #надо поставить, чтобы последняя строка в обработку попала
' | \
perl -ne '                                          #perl умеет работать как AWK
    $_=~s/\[\w*::[\w:]*\%*\d+\]:\w+/{IPV6}/g;       #ipv6 pattern
    $_=~s/\d+\.\d+\.\d+\.\d+\:\d+/{IPV4}/g;         #ipv4 pattern
    if(/dur=(\d+),evnt=EXCP.*Descr=(.*)/){
        $dur_ttl+=$1/1000;
        $dur{$2}+=$1/1000;
        $cnt_ttl+=1;
        $cnt{$2}+=1;
    }
    END{
        printf("=====TIME TOTAL(ms):%.2f      COUNT:%d      AVG(ms):%.2f\r\n",
               $dur_ttl,
               $cnt_ttl,
               $dur_ttl/$cnt_ttl);                  #формирую заголовок
        foreach $k (sort {$cnt{$b} <=> $cnt{$a}} keys %cnt) {
            printf "[][][] TIME(ms):%d [][][] TIME(%):%.2f [][][] COUNT:%d [][][] COUNT(%):%.2f [][][] BY:$k \r\n",
            $dur{$k},
            $dur{$k}/($dur_ttl>0?$dur_ttl:1)*100,
            $cnt{$k},
            $cnt{$k}/($cnt_ttl>0?$cnt_ttl:1)*100;   #сортирую массив по убыванию длительности и вывожу его
            last if ($_+=1)>10;                     #но только первые 10 строк
        }
    }'
