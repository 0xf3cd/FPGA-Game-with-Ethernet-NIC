#0 不用
#1 不用
#2 Switch 开关的值
#3 Timer 计时器待写入
#4 游戏单次等待时间
#5 VGA 屏幕待写入 左时间右分数
#6 EthernetNew输入
#7 计分
#8 Random 随机数读入
#9 Seg 7段数码管待写入数据
#10 一直为0x10010000
#11 to 20 随便用
#21 本轮剩余时间
#22 本轮图形颜色
#23 本轮图形形状
#24 本轮图形位置
#25 EthData1
#26 EthData2

#sw 800 804 814   81c    82c        830
#   VGA Seg Timer EthRst EthSendEna EthSendData
#
#lw 808 80c 814   820    824      828      834
#   Rdm Sw  Timer EthNew EthData1 EthData2 EthSendFinish

#lw remove 810Btn 818Rotary

addi $10, $0, 0x10010000
waitData:
lw   $6, 0x820($10)		#$6保存着网口是否有新数据，为1代表有
beq  $6, $0, waitData
lw   $26, 0x828($10)	#得到低32位数据，即按键情况
addi $19, $0, 1
sw   $19, 0x81c($10)	#复位网口数据
addi $19, $0, 0
sw   $19, 0x81c($10)	#复位网口数据

addi $11, $0, 0x0000ffff
waitForAWhile:
addi $11, $11, -1
bne  $11, $0, waitForAWhile

sw   $6, 0x830($10)
addi $11, $0, 1
sw   $11, 0x82c($10)
addi $11, $0, 0
sw   $11, 0x82c($10)

waitSendFinish:
lw   $5, 0x834($10)
beq  $5, $0, waitSendFinish
addi $19, $0, 1
sw   $19, 0x81c($10)	#复位网口数据
addi $19, $0, 0
sw   $19, 0x81c($10)	#复位网口数据

j    waitData