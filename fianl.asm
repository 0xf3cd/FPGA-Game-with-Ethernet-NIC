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

j    reset
exception:
mfc0 $30, $14
addi $30, $30, 4
mtc0 $30, $14

lw   $17, 0x808($10)
addi $16, $0, 4
divu $17, $16
mfhi $22					#得到余数，代表随机生成的颜色
lw   $18, 0x808($10)
addi $16, $0, 5
divu $18, $16
mfhi $18					#得到余数
addi $23, $18, 1			#代表随机生成的形状
lw   $19, 0x808($10)
addi $16, $0, 6
divu $19, $16
mfhi $24					#代表随机选择的出现位置

addi $5, $0, 0				#清空记录VGA输出的寄存器

addi $11, $0, 2
mul  $12, $11, $24			
addi $12, $12, 20			#颜色所需左移的位数
sllv $13, $22, $12
or   $5, $5, $13

addi $11, $0, 3
mul  $12, $11, $24			#形状所需左移的位数
sllv $13, $23, $12
or   $5, $5, $13			#$5保存了本次随机生成的VGA信息

sw   $5, 0x800($10)			#显示输出
eret

reset:
#reset 清空所有寄存器，VGA和七段数码管，以及计时模块
addi $2, $0, 0
addi $3, $0, 0
addi $4, $0, 0
addi $5, $0, 0
addi $6, $0, 0
addi $7, $0, 0
addi $8, $0, 0
addi $9, $0, 0
addi $21, $0, 0
addi $22, $0, 0
addi $23, $0, 0
addi $24, $0, 0
addi $10, $0, 0x10010000
sw   $5, 0x800($10)
sw	 $9, 0x804($10)
sw 	 $3, 0x814($10)
addi $19, $0, 1
sw   $19, 0x81c($10)	#复位网口数据
addi $19, $0, 0
sw   $19, 0x81c($10)	#复位网口数据

waitSW:
lw   $6, 0x820($10)		#$6保存着网口是否有新数据，为1代表有
beq  $6, $0, waitSW
lw   $26, 0x828($10)	#得到低32位数据，即按键情况
addi $19, $0, 1
sw   $19, 0x81c($10)	#复位网口数据
addi $19, $0, 0
sw   $19, 0x81c($10)	#复位网口数据
addi $11, $0, 0x000000ee
bne  $11, $26, waitSW

getGameDetail:
#sw[2:1] 决定游戏总时间        sw[4:3] 决定单次判断时间
#  00		 10				   00      0000afff
#  01        30                01      0000ffff
#  10        60                10      0001ffff
#  11       1500               11      0002ffff
lw   $2, 0x80c($10)
andi $12, $2, 6
sra  $12, $12, 1			#得到sw[2:1]的情况
andi $13, $2, 24 
sra  $13, $13, 3			#得到sw[4:3]的情况
	getTotalTime:
	addi $14, $0, 0
	beq  $12, $14, TotalTime00
	addi $14, $0, 1
	beq  $12, $14, TotalTime01
	addi $14, $0, 2
	beq  $12, $14, TotalTime10
	addi $14, $0, 3
	beq  $12, $14, TotalTime11
		TotalTime00:
		addi $3, $0, 11
		j    getOneTurnTime
		TotalTime01:
		addi $3, $0, 31
		j    getOneTurnTime
		TotalTime10:
		addi $3, $0, 61
		j    getOneTurnTime
		TotalTime11:
		addi $3, $0, 1501
		j    getOneTurnTime
	getOneTurnTime:
	addi $15, $0, 0
	beq  $13, $15, OneTurnTime00
	addi $15, $0, 1
	beq  $13, $15, OneTurnTime01
	addi $15, $0, 2
	beq  $13, $15, OneTurnTime10
	addi $15, $0, 3
	beq  $13, $15, OneTurnTime11
		OneTurnTime00:
		addi $4, $0, 0x0000afff
		j    preStart
		OneTurnTime01:
		addi $4, $0, 0x0000ffff
		j    preStart
		OneTurnTime10:
		addi $4, $0, 0x0001ffff
		j    preStart
		OneTurnTime11:
		addi $4, $0, 0x0002ffff
		j    preStart

preStart:
syscall
sw   $3, 0x814($10)			#开始游戏计时
addi $19, $0, 1
sw   $19, 0x81c($10)		#复位网口数据
addi $19, $0, 0
sw   $19, 0x81c($10)		#复位网口数据

gameMain:
	calculateRestTime:
	lw   $11, 0x814($10)   	#$11储存当前计时器的值
	addi $19, $11, 0		#$19同样储存当前计时器的值

	addi $20, $0, 0
	addi $12, $0, 1000
	div  $11, $12
	mflo $13				#商
	mfhi $14				#余数
	sll  $13, $13, 12
	or   $20, $20, $13

	add  $11, $0, $14
	addi $12, $0, 100
	div  $11, $12
	mflo $13				#商
	mfhi $14				#余数
	sll  $13, $13, 8
	or   $20, $20, $13

	add  $11, $0, $14
	addi $12, $0, 10
	div  $11, $12
	mflo $13				#商
	mfhi $14				#余数
	sll  $13, $13, 4
	or   $20, $20, $13

	or   $20, $20, $14		#此时$20储存了剩余时间对应的BCD码
	sll  $20, $20, 16
	andi $9, $9, 0x0000ffff #将左边计时部分清空
	or   $9, $9, $20		#补上新的计时部分
	sw   $9, 0x804($10)     #写入Seg

	beq  $19, $0, gameOver  #时间为0则游戏结束

	judgeThisTurn:
	beq  $21, $0, thisTurnEnd
	addi $21, $21, -1

	checkButton:
	lw   $6, 0x820($10)		#$6保存着网口是否有新数据，为1代表有
	beq  $6, $0, calculateRestTime
	lw   $26, 0x828($10)	#得到低32位数据，即按键情况
	addi $19, $0, 1
	sw   $19, 0x81c($10)	#复位网口数据
	addi $19, $0, 0
	sw   $19, 0x81c($10)	#复位网口数据

	addi $11, $0, 1
	beq  $23, $11, shape1
	addi $11, $0, 2
	beq  $23, $11, shape2
	addi $11, $0, 3
	beq  $23, $11, shape3
	addi $11, $0, 4
	beq  $23, $11, shape4
	addi $11, $0, 5
	beq  $23, $11, shape5
		shape1: #上
		addi $12, $0, 0x10
		bne  $12, $26, calculateRestTime
		j    getScore
		shape2: #下
		addi $12, $0, 0x8
		bne  $12, $26, calculateRestTime
		j    getScore
		shape3: #左
		addi $12, $0, 0x4
		bne  $12, $26, calculateRestTime
		j    getScore
		shape4: #右
		addi $12, $0, 0x2
		bne  $12, $26, calculateRestTime
		j    getScore
		shape5: #中
		addi $12, $0, 0x1
		bne  $12, $26, calculateRestTime
		j    getScore

getScore:
addi $7, $7, 15
addi $11, $7, 0			#$11储存当前分数

addi $20, $0, 0
addi $12, $0, 1000
divu $11, $12
mflo $13				#商
mfhi $14				#余数
sll  $13, $13, 12
or   $20, $20, $13

add  $11, $0, $14
addi $12, $0, 100
divu $11, $12
mflo $13				#商
mfhi $14				#余数
sll  $13, $13, 8
or   $20, $20, $13

add  $11, $0, $14
addi $12, $0, 10
divu $11, $12
mflo $13				#商
mfhi $14				#余数
sll  $13, $13, 4
or   $20, $20, $13

or   $20, $20, $14		#此时$20储存了分数对应的BCD码
andi $9, $9, 0xffff0000 #清空分数
or   $9, $9, $20
sw   $9, 0x804($10)     #写入Seg

thisTurnEnd:
add  $21, $4, $0
addi $22, $0, 0
addi $23, $0, 0
addi $24, $0, 0
addi $5, $0, 0
sw   $5, 0x800($10)			#清空屏幕

addi $11, $0, 0xfffff 
	waitForAWhile:
	addi $11, $11, -1
	bne  $11, $0, waitForAWhile

	generateNewShape:
	syscall

j    calculateRestTime

gameOver:
addi $5, $0, 0
sw   $5, 0x800($10)			#清空屏幕

sw   $9, 0x830($10)
addi $11, $0, 1
sw   $11, 0x82c($10)
addi $11, $0, 0
sw   $11, 0x82c($10)
waitSendFinish:
lw   $18, 0x834($10)
beq  $18, $0, waitSendFinish
addi $19, $0, 1
sw   $19, 0x81c($10)		#复位网口数据
addi $19, $0, 0
sw   $19, 0x81c($10)		#复位网口数据

andi $9, $9, 0x0000ffff		#清空七段数码管左边
ori  $9, $9, 0xfabc0000
addi $11, $0, 0xdddddddd
addi $13, $0, 0x1
addi $14, $0, 0x000000ff
	showDashAndScore:
	sw   $11, 0x804($10)	#写入Seg
	addi $12, $0, 0x006fffff
		waitShowDash:
		lw   $6, 0x820($10)	#$6保存着网口是否有新数据，为1代表有
		bne  $13, $6, DashHasNoData
		lw   $26, 0x828($10)
		addi $19, $0, 1
		sw   $19, 0x81c($10)	#复位网口数据
		addi $19, $0, 0
		sw   $19, 0x81c($10)	#复位网口数据
		beq  $26, $14, reset
			DashHasNoData:
			addi $12, $12, -1
			bne  $12, $0, waitShowDash

	sw   $9, 0x804($10)     #写入Seg
	addi $12, $0, 0x006fffff
		waitShowScore:
		lw   $6, 0x820($10)	#$6保存着网口是否有新数据，为1代表有
		bne  $13, $6, ScoreHasNoData
		lw   $26, 0x828($10)
		addi $19, $0, 1
		sw   $19, 0x81c($10)	#复位网口数据
		addi $19, $0, 0
		sw   $19, 0x81c($10)	#复位网口数据
		beq  $26, $14, reset
			ScoreHasNoData:
			addi $12, $12, -1
			bne  $12, $0, waitShowScore
	j   showDashAndScore
