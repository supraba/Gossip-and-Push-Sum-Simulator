                      
# Represents the node that maintains the global states for all the nodes in the topology
defmodule Server do
  use GenServer
  
  #The GenServer is started using this function
  def start_link(processIds, count2, nNodes, topology, algorithm) do
    GenServer.start_link(__MODULE__, [processIds, count2, nNodes, topology, algorithm] , name: :genMain) 
  end

  #The GenServer is initialized with initial values
  #processIds - list of processids of all processes 
  #count2 - number of processes that has received the rumour
  #nNodes - total number of nodes in the topology
  #topology - can be line, 2D, imperfect 2D and full
  #algorithm - can be either gossip or pushsum
  def init(processIds, count2, nNodes, topology, algorithm) do
    {:ok, processIds, count2, nNodes, topology, algorithm}
  end

  #setter for all states
  def handle_call({:updateProcessIDs, pid}, _from, [processIds, count2, nNodes, topology, algorithm]) do
    {:reply, processIds, [processIds++[pid], count2, nNodes, topology, algorithm]}
  end

  def handle_cast({:updateNNodes,newNNodes},[processIds, count2, nNodes, topology, algorithm]) do
    {:noreply,[processIds, count2, newNNodes, topology, algorithm]}
  end

  def handle_call(:incrementCount2, _from, [processIds, count2, nNodes, topology, algorithm]) do
    {:reply, count2, [processIds, count2+1, nNodes, topology, algorithm]}
  end

  #getter for all states
  def handle_call({:getProcessID, i}, _from, [processIds, count2, nNodes, topology, algorithm]) do
    {:reply, Enum.at(processIds, i), [processIds, count2, nNodes, topology, algorithm]}
  end

  def handle_call(:getCount2, _from, [processIds, count2, nNodes, topology, algorithm]) do
    {:reply, count2, [processIds, count2, nNodes, topology, algorithm]}
  end

  def handle_call(:getNNodes, _from, [processIds, count2, nNodes, topology, algorithm]) do
    {:reply, nNodes, [processIds, count2, nNodes, topology, algorithm]}
  end

  def handle_call(:getTopology, _from, [processIds, count2, nNodes, topology, algorithm]) do
    {:reply, topology, [processIds, count2, nNodes, topology, algorithm]}
  end

  def handle_call(:getAlgorithm, _from, [processIds, count2, nNodes, topology, algorithm]) do
    {:reply, algorithm, [processIds, count2, nNodes, topology, algorithm]}
  end

  #Creates n nodes in the topology
  def createNodes(nNodes, i) do
    if i<nNodes do
      {_, pid} = Worker.start_link(0,i+1,1,0,0,i,[],1)

      s = GenServer.call pid, :getS
      w = GenServer.call pid, :getW
      # IO.inspect [s,w]

      # IO.puts "#{inspect pid}"
      GenServer.call :genMain, {:updateProcessIDs,pid}
      computeNeighbors(nNodes, i)
      createNodes(nNodes, i+1)
    end
  end

  #computes the neighbours of a node
  def computeNeighbors(nNodes, i) do
    neighbors = []
    # IO.puts "#{inspect i}"
    topology =  GenServer.call :genMain, :getTopology
    if topology == "line" do
        if i > 0 do
          neighbors  =  neighbors ++ [i - 1]
        end
        lastN = nNodes-1
        if i < lastN do
          neighbors  =  neighbors ++ [i + 1]
        end
    end
    if (topology == "2d" ||topology=="imp2d" ) do
      d2nodes = :math.sqrt(nNodes)
      if d2nodes!= round(:math.sqrt(nNodes))do
          makeperfect2D(nNodes,d2nodes)
      end
      nNodes = GenServer.call :genMain, :getNNodes
      j = round(:math.sqrt(nNodes))
      if rem(i,j) == 0 do
        neighbors = neighbors ++ [i + 1]
      end
      if rem((i+1) , j) == 0 do
        neighbors = neighbors ++ [i - 1]
      end
      if i - j < 0 do
        neighbors = neighbors ++ [i + j]
      end
      if (i - (nNodes - j) >= 0) do
        neighbors = neighbors ++ [i - j]
      end
      if (nNodes > 4) do
        if ((rem(i,j) != 0) && (rem((i + 1), j) != 0)) do
          neighbors = neighbors ++ [i - 1]
          neighbors = neighbors ++ [i + 1]
        end
        if ((i - j > 0) && (i - (nNodes - j) < 0)) do
          neighbors = neighbors ++ [i + j]
          neighbors = neighbors ++ [i - j]
        end
        if (i == j) do
          neighbors = neighbors ++ [i - j]
          neighbors = neighbors ++ [i + j]
        end
      end
      # if the toplogy is Imperfect 2D add a random neighbor
      if(topology=="imp2d") do
        random= findRandom(i,nNodes)
        neighbors = neighbors ++ [random]
      end
    end
    pid  = GenServer.call :genMain, {:getProcessID,i}
    GenServer.call pid, {:updateNeighbors,neighbors}
  end

  # To make the nNodes perfectsqaure
  def makeperfect2D(nNodes,d2nodes)  do
      if d2nodes == round(:math.sqrt(nNodes)) do
        GenServer.cast(:genMain ,{:updateNNodes,nNodes})
      else
        nNodes=nNodes+1
        d2nodes =:math.sqrt(nNodes) 
        makeperfect2D(nNodes,d2nodes) 
      end
  end 
  
  # Finds random number otherthan itself
  def findRandom(i,nNodes) do
      if i == (:rand.uniform(nNodes)-1) do
        findRandom(i,nNodes)
      else  
        :rand.uniform(nNodes) - 1
      end
  end

  #implements the gossip protocol
  def gossip(i) do  
    pid = GenServer.call :genMain, {:getProcessID,i}
    count =  GenServer.call pid, :getCount #count
    if count < 10 do
      if count == 0 do
        #increment the total number of nodes that has received the rumour by 1 when a node receives the rumor for the first time
        GenServer.call :genMain, :incrementCount2 
      end
      GenServer.call pid, :incrementCount
      nNodes =  GenServer.call :genMain, :getNNodes
      count2 =  GenServer.call :genMain, :getCount2
      Main.checkConvergence(nNodes, 0, [])
      repeatGossip(pid, 0)
    else 
      GenServer.call pid, :updateState # this marks the process's state as 0, so that it is not selected for transmission again
    end
  end

  #once a rumour is received by a node it is transmitted 5 times to any of it's neighbors
  def repeatGossip(pid, j) do
    count = GenServer.call pid, :getCount
    if j<5 and count< 10 do
      # for full topology we are not calculating neighbour list just picking any random node except the current node
      totalCount = GenServer.call :genMain, :getCount2
      nNodes = GenServer.call :genMain, :getNNodes
      i = GenServer.call pid, :getI
      if totalCount<nNodes do
        topology =  GenServer.call :genMain, :getTopology
        if topology == "full" do 
          gossipFull(i, nNodes, :rand.uniform(nNodes)-1,0)
        else
          neighbors = GenServer.call pid, :getNeighbors
          randomNum = :rand.uniform(Enum.count(neighbors))-1
          gossipLoop(i, randomNum, Enum.count(neighbors), neighbors, 0)       
        end
        repeatGossip(pid, j+1)
      end

    end  
  end
  
#Finds a neighbor node that is alive (count<10) for all topologies other than full topology
  def gossipLoop(i, randomNum, neighBorLen, neighbors, countLoop) do
    if countLoop<100 do #countLoop has been added to handle node failure
      randomNeigh =  Enum.at(neighbors, randomNum)
      pid = GenServer.call :genMain, {:getProcessID, randomNeigh}
      state = GenServer.call pid, :getState
      if i != randomNeigh and state == 1 do
        gossip(randomNeigh) 
      else
        gossipLoop(i, :rand.uniform(neighBorLen)-1, neighBorLen, neighbors, countLoop+1)
      end
    end
  end

  #Finds an alive neighbor node for full topology
  def gossipFull(i, nNodes, randomNum, countLoop) do
    if countLoop<nNodes do
      pid = GenServer.call :genMain, {:getProcessID, randomNum}
      state = GenServer.call pid, :getState
      if i != randomNum and state == 1 do
        gossip(randomNum) 
      else
        gossipFull(i, nNodes, :rand.uniform(nNodes)-1, countLoop+1)
      end
    end
  end

  
  #implements the pushsum protocol
  def pushSum(s_new, w_new, i) do
    pid = GenServer.call :genMain, {:getProcessID,i}
    count = GenServer.call pid, :getCount
    state = GenServer.call pid, :getState
    s = GenServer.call pid, :getS
    w = GenServer.call pid, :getW
    s_prev = GenServer.call pid, :getS_Prev
    w_prev = GenServer.call pid, :getW_Prev

    s = s + s_new
    w = w + w_new
 
    
    if count<3 do
      if (s_prev != 0) and (w_prev != 0) do
        diff = abs((s_prev/w_prev) - (s/w))   #checking if (s/w) value differs by only 10^-10 in 3 consecutive rounds
        #IO.inspect ['diff',diff]
        if diff <= :math.pow(10,-10) do
            GenServer.call pid, :incrementCount
        else
            GenServer.call pid, :resetCount
        end
      end
    else 
        if state==1 do
          n = s/w
          GenServer.call pid, :updateState
          state = 0
        end
    end

    if state==1 do
      GenServer.call pid, {:updateS_Prev,s} #s_prev = s
      GenServer.call pid, {:updateW_Prev,w} #w_prev = w
      
      # IO.puts "  "
      # IO.puts "s,w before update"
      # IO.inspect [s,w]   

      s = s-s/2
      w = w-w/2
      

      # IO.puts "s,w after update"
      # IO.inspect [s,w]
      # IO.puts "  "
      
      GenServer.call pid, {:updateS,s} # s -= s/2
      GenServer.call pid, {:updateW,w} # w -= w/2

      topology =  GenServer.call :genMain, :getTopology
      nNodes = GenServer.call :genMain, :getNNodes
      if topology == "full" do
        randomNum = pushSumFull(i, nNodes, :rand.uniform(nNodes)-1)
      else
        neighbors = GenServer.call pid, :getNeighbors
        randomNum = :rand.uniform(Enum.count(neighbors))-1
        randomNum = pushSumLoop(i, randomNum, Enum.count(neighbors), neighbors)
      end
      #IO.inspect ['randomNum',randomNum]
      pushSum(s, w, randomNum)      
    end
  end

  #Finds a neighbor node for all topologies other than full topology
  def pushSumLoop(i, randomNum, neighBorLen, neighbors) do
      randomNeigh =  Enum.at(neighbors, randomNum)
      pid = GenServer.call :genMain, {:getProcessID, randomNeigh}
      if i != randomNeigh do
        randomNeigh
      else
        pushSumLoop(i, :rand.uniform(neighBorLen)-1, neighBorLen, neighbors)
      end
  end

  #Finds a neighbor node for full topology
  def pushSumFull(i, nNodes, randomNum) do
      pid = GenServer.call :genMain, {:getProcessID, randomNum}
      if i != randomNum  do
        randomNum 
      else
        pushSumFull(i, nNodes, :rand.uniform(nNodes)-1)
      end
  end

end

#The code execution starts from here
defmodule Main do
  def main(args) do
    args |> parse_args  
  end
    
  defp parse_args([]) do
    IO.puts "No arguments given. Enter the value of k again"
  end

  defp parse_args(args) do
    {_,k,_} = OptionParser.parse(args)
    # IO.puts "#{inspect Enum.count(k)}"
     
    if Enum.count(k) == 3 do
      {nNodes, _} = Integer.parse(Enum.at(k,0))
      topology =  String.downcase(Enum.at(k,1))
      algorithm = String.downcase(Enum.at(k,2))
    else
     IO.puts "Enter number of nodes, topology and algorithm" 
    end


    Server.start_link([], 0, nNodes, topology, algorithm)
    if(topology == "2d" || topology == "imp2d") do
      d2nodes = :math.sqrt(nNodes)
      if d2nodes!= round(:math.sqrt(nNodes))do
        Server.makeperfect2D(nNodes,d2nodes)
      end
    end   
    nNodes = GenServer.call :genMain, :getNNodes
    Server.createNodes(nNodes, 0)

    startNode = :rand.uniform(nNodes)-1 #a random node is chosen as the starting point
    st_time = :os.system_time(:millisecond)

    if algorithm == "gossip" do
      Server.gossip(startNode)
      count2  = GenServer.call :genMain, :getCount2
      # IO.inspect ['count2',count2]
    else
      Server.pushSum(0,0,startNode)
    end
    en_time = :os.system_time(:millisecond)    
    if count2 == nNodes or algorithm == "push-sum" do
      IO.puts "The algorithm converged in #{inspect en_time-st_time} milliseconds"
      
    else
      IO.puts "The algorithm failed to converge due to node failure"
    end

  end

  #Prints the count of all the nodes in the topology
  #For debugging
  def checkConvergence(nNodes, i, list) do
    if i<nNodes do
      if  rem(i,20) == 0 do
        list = []
      end
      
      pid  = GenServer.call :genMain, {:getProcessID,i}
      count = GenServer.call pid, :getCount
      list = list ++ [count]
      checkConvergence(nNodes, i+1, list)
    else
      # IO.inspect list
    end
  end

end

# Represents a node in the topology
defmodule Worker do
  use GenServer
  
  #The GenServer is started using this function
  def start_link(count, s, w, s_prev, w_prev, i, neighbor, state) do
    GenServer.start_link(__MODULE__, [count, s, w, s_prev, w_prev, i, neighbor, state] ) 
  end

  #The GenServer is initialized with initial values
  #count - the number of times a process has received the rumour
  #s - sum value of a node
  #w - weight of a node
  #i - index of a node
  #neighbor - list of neighbouring nodes for a given node
  #state - 1 denotes that it is alive. 0 denotes that it is will no longer transmit messages.
  def init(count, s, w, s_prev, w_prev, i, neighbor, state) do
    {:ok, count, s, w, s_prev, w_prev, i, neighbor, state}
  end

  def handle_call(:incrementCount, _from, [count, s, w, s_prev, w_prev, i, neighbor, state]) do
    {:reply, count, [count+1, s, w, s_prev, w_prev, i, neighbor, state]}
  end

  def handle_call(:resetCount, _from, [count, s, w, s_prev, w_prev, i, neighbor, state]) do
    {:reply, count, [0, s, w, s_prev, w_prev, i, neighbor, state]}
  end

  #setters for all the state values
  def handle_call(:getCount, _from, [count, s, w, s_prev, w_prev, i, neighbor, state]) do
    {:reply, count, [count, s, w, s_prev, w_prev, i, neighbor, state]}
  end

  def handle_call({:updateS, new_s},_from, [count, s, w, s_prev, w_prev, i, neighbor, state]) do
    {:reply, s, [count, new_s, w, s_prev, w_prev, i, neighbor, state]}
  end

  def handle_call({:updateW, new_w},_from, [count, s, w, s_prev, w_prev, i, neighbor, state]) do
    {:reply, w, [count, s, new_w, s_prev, w_prev, i, neighbor, state]}
  end

  def handle_call({:updateS_Prev, new_s_prev},_from, [count, s, w, s_prev, w_prev, i, neighbor, state]) do
    {:reply, s_prev, [count, s, w, new_s_prev, w_prev, i, neighbor, state]}
  end

  def handle_call({:updateW_Prev, new_w_prev},_from, [count, s, w, s_prev, w_prev, i, neighbor, state]) do
    {:reply, w_prev, [count, s, w, s_prev, new_w_prev, i, neighbor, state]}
  end

  def handle_call({:updateNeighbors, newNeigh},_from, [count, s, w, s_prev, w_prev, i, neighbor, state]) do
    {:reply, neighbor,[count, s, w, s_prev, w_prev, i, neighbor ++ newNeigh,state]}
  end  

  def handle_call(:updateState, _from, [count, s, w, s_prev, w_prev, i, neighbor, state]) do
    {:reply, 0,[count, s, w, s_prev, w_prev, i, neighbor, 0]}
  end

  #getters for all the state values
  def handle_call(:getCount, _from, [count, s, w, s_prev, w_prev, i, neighbor, state]) do
    {:reply, count, [count, s, w, s_prev, w_prev, i, neighbor, state]}
  end

  #added by pradosa
  def handle_call(:getSbyW, _from, [count, s, w, s_prev, w_prev, i, neighbor, state]) do
    {:reply, s/w, [count, s, w, s_prev, w_prev, i, neighbor, state]}
  end

  def handle_call(:getS, _from, [count, s, w, s_prev, w_prev, i, neighbor, state]) do
    {:reply, s, [count, s, w, s_prev, w_prev, i, neighbor, state]}
  end

  def handle_call(:getW, _from, [count, s, w, s_prev, w_prev, i, neighbor, state]) do
    {:reply, w, [count, s, w, s_prev, w_prev, i, neighbor, state]}
  end

  def handle_call(:getS_Prev, _from, [count, s, w, s_prev, w_prev, i, neighbor, state]) do
    {:reply, s_prev, [count, s, w, s_prev, w_prev, i, neighbor, state]}
  end

  def handle_call(:getW_Prev, _from, [count, s, w, s_prev, w_prev, i, neighbor, state]) do
    {:reply, w_prev, [count, s, w, s_prev, w_prev, i, neighbor, state]}
  end

  def handle_call(:getI, _from, [count, s, w, s_prev, w_prev, i, neighbor, state]) do
    {:reply, i, [count, s, w, s_prev, w_prev, i, neighbor, state]}
  end

  def handle_call(:getNeighbors, _from, [count, s, w, s_prev, w_prev, i, neighbor, state]) do
    {:reply, neighbor, [count, s, w, s_prev, w_prev, i, neighbor, state]}
  end

  def handle_call(:getState, _from, [count, s, w, s_prev, w_prev, i, neighbor, state]) do
    {:reply, state, [count, s, w, s_prev, w_prev, i, neighbor, state]}
  end

end