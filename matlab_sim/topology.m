   classdef topology
   % write a description of the class here.
       properties
       % define the properties of the class here, (like fields of a struct)
           nodes;
           edges;           
       end
       methods
       % methods, including the constructor are defined in this block
           function obj = topology(nodes, edges)
           % class constructor
               if(nargin > 0)
                 obj.nodes = nodes;
                 obj.edges = edges;                 
               end
           end
           function node = getNode(obj, node_id)
               if node_id <= size(obj.nodes,1)
                   node = obj.nodes(node_id, :);
               else
                   throw(MException('TOPOLOGY:getNode', strcat('topology does not contain node with requested id=', int2str(node_id))))
               end;
           end 
           function edge = getEdge(obj, edge_id)
               if edge_id <= size(obj.edges,1)
                   edge = obj.edges(edge_id, :);
               else
                   throw(MException('TOPOLOGY:getEdge', strcat('topology does not contain edge with requested id=', int2str(edge_id))))
               end;
           end 
           function [node_ids, edge_ids] = adjacentNodesAndLinks(obj, node_id)
                current_node = obj.getNode(node_id);
                
                node_ids = cell2mat(current_node.neighbors.keySet.toArray.cell);
                edge_ids = cell2mat(current_node.neighbors.values.toArray.cell);
           end;
           function node_number = getNodeNumber(obj)
                node_number = size(obj.nodes,1);
           end;
           function edge_number = getEdgeNumber(obj)
                edge_number = size(obj.edges,1);
           end;
           function edges = get.edges(obj)
               edges = obj.edges;               
           end
           function nodes = get.nodes(obj)
               nodes = obj.nodes;               
           end
       end
   end