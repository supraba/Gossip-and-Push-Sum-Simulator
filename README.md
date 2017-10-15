# Gossip-and-Push-Sum-Simulator
Team Members: 
Pradosa Patnaik
UFID: 1288-9584
Supraba Muruganantham 
UFID : 9215-9813
What is working?
We have implemented both the Gossip and Push-Sum algorithms for the below four topologies using Elixir Genserver processes.
	Full Network
	2D Grid
	Line
	Imperfect 2D Grid
Full Network:
To run Gossip algorithm using Full network topology the command is as follows:
 Compile the project from the project2 directory.
$ mix escript.build
Run the project with the command
$  ./project2 49 full gossip
To run Push-Sum algorithm using Full network topology the command is as follows:
$  ./project2 49 full pus-sum
2D Grid: 
To run Gossip algorithm using 2D network topology the command is as follows:
$  ./project2 49 2D gossip
To run Push-Sum algorithm using 2D network topology the command is as follows:
$  ./project2 49 2D push-sum

Line:
To run Gossip algorithm using Line network topology the command is as follows:
 $  ./project2 49 line gossip
To run Push-Sum algorithm using Line network topology the command is as follows:
 $  ./project2 49 line push-sum
Imperfect 2D Grid:
To run Gossip algorithm using Imperfect 2D Grid network topology the command is as follows:
$  ./project2 49 2D gossip
To run Push-Sum algorithm using Imperfect 2D Grid network topology the command is as follows:
$  ./project2 49 2D push-sum

What is the largest network you managed to deal with for each type of topology and algorithm?
Gossip Algorithm:
Full Network:
For nodes= 10000 we are getting the total time for Full network using Gossip algorithm as 530.562 seconds
Imperfect 2D Grid:
For nodes = 10000 we are getting the total time for imp2D using Gossip algorithm as 760.556 seconds
2D Grid:
For nodes= 4900 we are getting the total time for 2D using Gossip algorithm as 4500.426 seconds
Line:
For nodes= 4900 we are getting the total time for Line using Gossip algorithm as 5610.364 seconds
Push-Sum Algorithm:
Full Network :
For nodes= 10000 we are getting the total time for Full network using Gossip algorithm as 90.002 seconds
Imperfect 2D Grid :
For nodes = 10000 we are getting the total time for imp2D using Gossip algorithm as 350.80 seconds

2D Grid :
For nodes= 4900 we are getting the total time for 2D using Gossip algorithm as 1600.212 seconds
Line :
For nodes= 4900 we are getting the total time for Line using Gossip algorithm as 1746.66 seconds

