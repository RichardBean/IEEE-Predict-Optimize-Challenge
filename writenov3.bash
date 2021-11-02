for i in phase2_instance_large_[24].sol
do
grep roomlimit $i | grep -v roomlimito | sort -k2n | awk '$NF' | tr '\[\],' ' ' | tr -d '\015' | grep -v e-1 | awk '{printf("%s %s %.0f\n",$2,$3,$4);}' | sort -n | awk '{if (x!=$1) printf("\n"); for(i=1;i<=$NF;i++) printf("%d ",($2 >= 2) ? ($2+1) : $2);  x=$1; }END{ printf("\n");}' | awk '{print NF,$0}' > roomsol
grep roomlimitoo $i | sort -k2n | awk '$NF' | tr '\[\],' ' ' | tr -d '\015' | grep -v e-1 | awk '{printf("%s %s %.0f\n",$2,$3,$4);}' | sort -n | awk '{if (x!=$1) printf("\n"); for(i=1;i<=$NF;i++) printf("%d ",($2 >= 2) ? ($2+1) : $2);  x=$1; }END{ printf("\n");}' | awk '{print NF,$0}' > roomsolo
head -2 ../p2orig/phase2_instance_solution_large_0.txt > hd # all same
grep z $i | grep -v zo | grep -v z0 | grep -v z0o | tr '\[\]' ' ' | sort -k2n | awk '{printf("%.0f\n",$3);}' > hd2
grep zo $i | grep -v z0o | grep -v dayzo | tr '\[\]' ' ' | sort -k2n | awk '{printf("%.0f\n",$3);}' > hd2o
grep ^r phase2_instance_large_4.txt | awk '{print $1,$2}' > lh
head -100 lh | tr r a > lho  ## 20 for large 100 for large
grep "bat[cd]" $i | awk '$NF'  | grep -v e-1 | tr '\[\],' ' ' | sort -k2,2n -k3,3n | awk '{printf("c %d %d %d\n",$2,$3,($1=="batd")?2:0);}' > bat
sum bat
# (cat hd; paste lh hd2 roomsol | tr '\t' ' '; cat bat) | tr -d '\015' | sed 's/ $//' > `echo $i | sed 's/sol$/txt/' | sed 's/instance/instance_solution/'` # phase2_instance_solution_large_0.txt
(cat hd; paste lh hd2 roomsol | tr '\t' ' '; paste lho hd2o roomsolo | tr '\t' ' '; cat bat ) | tr -d '\015' | sed 's/ $//' > `echo $i | sed 's/sol$/txt/' | sed 's/instance/instance_solution/'`
done
