   classdef node
   % write a description of the class here.
       properties
       % define the properties of the class here, (like fields of a struct)
           id;
           x = 0;
           y = 0;           
           neighbors; %containers.Map('KeyType','int32','ValueType','int32');
       end
       methods
       % methods, including the constructor are defined in this block
           function obj = node(id, x, y)
           % class constructor
               if(nargin > 0)
                 obj.id = id;
                 obj.x = x;
                 obj.y = y;
                 obj.neighbors = java.util.HashMap;
               end
           end
           function id = get.id(obj)
               id = obj.id;               
           end
           function x = get.x(obj)
               x = obj.x;               
           end
           function y = get.y(obj)
               y = obj.y;               
           end
           function neighbors = get.neighbors(obj)
               neighbors = obj.neighbors;               
           end 
           function addNeighbors(obj, node_id, edge_id)
               %obj.neighbors(node_id) = edge_id;  
               obj.neighbors.put(node_id, edge_id);               
           end             
       end
   end