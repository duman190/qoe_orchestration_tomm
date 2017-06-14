   classdef edge
   % write a description of the class here.
       properties
       % define the properties of the class here, (like fields of a struct)
           id;
           src;
           dst;
           delay;
           cost;
           bw;
       end
       methods
       % methods, including the constructor are defined in this block
           function obj = edge(id, src, dst, delay, bw, cost)
           % class constructor
               if(nargin > 0)
                 obj.id = id;
                 obj.src = src;
                 obj.dst = dst; 
                 obj.delay = delay; %in this model we roughly suggest that our propagation delay == length of the edge
                 obj.bw = bw; %round to avoid extreme accuracy
                 obj.cost = cost;%rand*8+1;
               end
           end
           function id = get.id(obj)
               id = obj.id;               
           end
           function src = get.src(obj)
               src = obj.src;               
           end
           function dst = get.dst(obj)
               dst = obj.dst;               
           end
           function delay = get.delay(obj)
               delay = obj.delay;               
           end
           function bw = get.bw(obj)
               bw = obj.bw;               
           end
           function cost = get.cost(obj)
               cost = obj.cost;               
           end
       end
   end