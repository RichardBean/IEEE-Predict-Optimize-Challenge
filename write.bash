for i in phase2_instance_small_?.sol
do
grep roomlimit $i | grep -v roomlimito | sort -k2n | awk '$NF' | tr '\[\],' ' ' | tr -d '\015' | grep -v e-1 | awk '{printf("%s %s %.0f\n",$2,$3,$4);}' | sort -n | awk '{if (x!=$1) printf("\n"); for(i=1;i<=$NF;i++) printf("%d ",($2 >= 2) ? ($2+1) : $2);  x=$1; }END{ printf("\n");}' | awk '{print NF,$0}' > roomsol
head -2 ../p2orig/phase2_instance_solution_small_0.txt > hd
grep z $i | grep -v zo | grep -v z0 | tr '\[\]' ' ' | sort -k2n | awk '{printf("%.0f\n",$3);}' > hd2
grep ^r `echo $i | sed 's/sol/txt/'` | awk '{print $1,$2}' > lh
grep "bat[cd]" $i | awk '$NF'  | grep -v e-1 | tr '\[\],' ' ' | sort -k2,2n -k3,3n | awk '{printf("c %d %d %d\n",$2,$3,($1=="batd")?2:0);}' > bat
sum bat
(cat hd; paste lh hd2 roomsol | tr '\t' ' '; cat bat) | tr -d '\015' | sed 's/ $//' > `echo $i | sed 's/sol$/txt/' | sed 's/instance/instance_solution/'` # phase2_instance_solution_small_0.txt
done
####
for i in phase2_instance_large_[013].sol
do
grep roomlimit $i | sort -k2n | awk '$NF' | tr '\[\],' ' ' | tr -d '\015' | grep -v e-1 | awk '{printf("%s %s %.0f\n",$2,$3,$4);}' | sort -n | awk '{if (x!=$1) printf("\n"); for(i=1;i<=$NF;i++) printf("%d ",($2 >= 2) ? ($2+1) : $2);  x=$1; }END{ printf("\n");}' | awk '{print NF,$0}' > roomsol
head -2 ../p2orig/phase2_instance_solution_large_0.txt > hd
grep z $i | grep -v z0 | tr '\[\]' ' ' | sort -k2n | awk '{printf("%.0f\n",$3);}' > hd2
grep ^r `echo $i | sed 's/sol/txt/'` | awk '{print $1,$2}' > lh
grep "bat[cd]" $i | awk '$NF'  | grep -v e-1 | tr '\[\],' ' ' | sort -k2,2n -k3,3n | awk '{printf("c %d %d %d\n",$2,$3,($1=="batd")?2:0);}' > bat
sum bat
(cat hd; paste lh hd2 roomsol | tr '\t' ' '; cat bat) | tr -d '\015' | sed 's/ $//' > `echo $i | sed 's/sol$/txt/' | sed 's/instance/instance_solution/'` # phase2_instance_solution_small_0.txt
done
