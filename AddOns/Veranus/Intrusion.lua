

-----------入侵提示
local h,n,l,a;
h=(time()-1545170400)/3600;
n=math.modf(h/19)%6+1;
l=h%19;
a={"祖达萨","提拉加德海峡","纳兹米尔","斯托颂谷地","沃顿","德鲁斯瓦","祖达萨"};
local msg = l<7 and string.format('正在入侵：%s(剩余%.1f小时)',a[n],7-l) or string.format('下次入侵：%s(%.1f小时后)',a[n+1],19-l)
--message(msg)
print(msg)



 