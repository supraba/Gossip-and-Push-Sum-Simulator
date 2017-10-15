## Gossip-and-Push-Sum-Simulator
We have implemented both the Gossip and Push-Sum algorithms for the below four topologies using Elixir Genserver processes.<br /><br />
	Full Network <br />
	2D Grid <br />
	Line <br />
	Imperfect 2D Grid <br />

#### Full Network:
To run Gossip algorithm using Full network topology the command is as follows:<br />
###### Compile the project from the project2 directory.<br />
*$ mix escript.build*<br />
###### Run the project with the command<br />
*$ ./project2 49 full gossip*<br />
###### To run Push-Sum algorithm using Full network topology the command is as follows:<br />
*$ ./project2 49 full push-sum*<br />

#### 2D Grid:
###### To run Gossip algorithm using 2D network topology the command is as follows:<br />
*$ ./project2 49 2D gossip*<br />
###### To run Push-Sum algorithm using 2D network topology the command is as follows:<br />
*$ ./project2 49 2D push-sum*<br />

#### Line:
###### To run Gossip algorithm using Line network topology the command is as follows:<br />
*$ ./project2 49 line gossip*<br />

###### To run Push-Sum algorithm using Line network topology the command is as follows:<br />
*$ ./project2 49 line push-sum*<br />

#### Imperfect 2D Grid:
###### To run Gossip algorithm using Imperfect 2D Grid network topology the command is as follows:<br />
*$ ./project2 49 2D gossip*<br />

###### To run Push-Sum algorithm using Imperfect 2D Grid network topology the command is as follows:<br />
*$ ./project2 49 2D push-sum*<br /><br />

### The largest network built for each type of topology and algorithm:<br /><br />
                                                            
                                                   Gossip Algorithm
#### Full Network:
For nodes= 10000, total time for Full network = 530.562 s<br />

#### Imperfect 2D Grid:
For nodes = 10000, total time for imp2D network = 760.556 s<br />

#### 2D Grid:
For nodes= 4900, total time for 2D network = 4500.426 s<br />

#### Line:
For nodes= 4900, total time for Line network = 5610.364 s<br />

                                                   Push-Sum Algorithm
#### Full Network :
For nodes= 10000, total time for Full network = 90.002 s<br />

#### Imperfect 2D Grid :
For nodes = 10000, total time for imp2D network = 350.80 s<br />

#### 2D Grid :
For nodes= 4900, total time for 2D network = 1600.212 s<br />

#### Line :
For nodes= 4900, total time for Line network = 51746.66 s<br />
