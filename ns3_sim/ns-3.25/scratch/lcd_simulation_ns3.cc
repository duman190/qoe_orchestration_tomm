/* -*- Mode:C++; c-file-style:"gnu"; indent-tabs-mode:nil; -*- */
/*
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License version 2 as
 * published by the Free Software Foundation;
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
 *
 */

#include <string>
#include "ns3/core-module.h"
#include "ns3/network-module.h"
#include "ns3/internet-module.h"
#include "ns3/point-to-point-module.h"
#include "ns3/mobility-module.h"
#include "ns3/applications-module.h"
#include "ns3/brite-module.h"
//#include "ns3/ipv4-nix-vector-helper.h"
#include <iostream>
#include <fstream>
#include "myapp.h"
#include <math.h>

using namespace ns3;
using namespace std;

NS_LOG_COMPONENT_DEFINE ("BriteExample");

const int schemeType = 1; //0-lcd,1-BR,2-LB,3-CM,4-AMP-SMP 
const int serverNum=1;      //Number of server
const int N = 20;           // Number of total nodes
const int sCap = 25;        //Number of clients which can be served by server without degradation
const int total_client=N-serverNum;  // Number of clients

std::string confFile = "RTBarabasi100.conf"; //config file for BRITE
std::string topoName = "b1";

  double U[N][serverNum];
  int Servers[serverNum];
  int Capacity[serverNum];
  
  int CS[serverNum]; //# of clients per server 
  int US[total_client]; //client's server id
  int IS[total_client]; //client's server index
  int IC[total_client]; //client id
  int prevServer[total_client];      
  uint64_t lastTotalRx[total_client];
  double qoeThresh = 4; //QoE threshold to define satisfied users
  int totalAdaptNum=0;
  double alpha_qoe = 1.01; 
  double totalTime = 211;
  double timeInterval = 20;
  int globalDisrupt = 0;

// client structure
struct clients{
        int C;
        int N;
        int S;
        int Type;
        double prevQoE;
        int Disrupt;
};

clients * client= new clients[total_client];

void readFromFile()
{
   string fileName;
   if(serverNum==1)
   {
        fileName = "pcm_1_servers.txt";
   }
   else if(serverNum==2)
   {
        fileName = "pcm_2_servers.txt";
   }
   else if(serverNum==5)
   {
        fileName = "pcm_5_servers.txt";
   }
   else if(serverNum==10)
   {
        fileName = "pcm_10_servers.txt";
   }
   else if(serverNum==25)
   {
        fileName = "pcm_25_servers.txt";
   }
   else if(serverNum==50)
   {
        fileName = "pcm_50_servers.txt";
   }
   cout<<fileName<<"\n";
   ifstream myReadFile;
   string text;
   myReadFile.open(fileName.c_str());
   if(myReadFile.is_open())
   {
       //cout<<"U["<<N<<"]["<<serverNum<<"]=\n";
       //read assignment probabilities
        for(int j=0;j<N;j++)
        {
                getline(myReadFile,text);
                istringstream iss(text);
                for(int i=0;i<serverNum;i++)
                {
                    iss>>skipws>>U[j][i];
                    //cout<<U[j][i]<<"  ";
                }
                //cout<<"\n";
        }
       //read servers
        getline(myReadFile,text);
        istringstream iss(text);
        for(int i=0;i<serverNum;i++)
        {
                iss>>skipws>>Servers[i];
                Servers[i]=Servers[i]-1;
                //cout<<"Server["<<i<<"]="<<Servers[i]<<" ";                    
        }
        //cout<<"\n";
   }
   else
   {
        cout<<"can't open file \n";
   }
   cout<<"finish reading"<<"\n";
   myReadFile.close();
}
  

void updateNumberClient()
{
        for(int i=0;i<N-total_client;i++)
        {
              CS[i]=0;
        }
        for(int i=0;i<total_client;i++)
        {
              CS[IS[i]]++;
        }
}

int getSecondUMinClient(int i, int curServerIndex)
{
  double second_max=0;
//  int minClients = N;
  int second_index=-1;
// Get the second max i for client id, j for server index (e.g., 1..M)
 for(int j=0;j<serverNum;j++)
 {
       if(j!=curServerIndex && U[i][j] > second_max)
        {
           second_index=j;
           second_max=U[i][j];
        }
 }
/* No need for load balancing
if (second_index == -1)
{
   for(int j=0;j<serverNum;j++)
 {
       if(j!=curServerIndex && CS[j] < minClients)
        {
           second_index=j;
           minClients=CS[j];
        }
 }
}
*/
return second_index;
}

int getLBServer(int i, int curServerIndex)
{
  double second_max=0;
  int minClients = N;
  int second_index=-1;
// Get the second max i for client id, j for server index (e.g., 1..M)
 for(int j=0;j<serverNum;j++)
 {
       if(j!=curServerIndex && U[i][j] > second_max)
        {
           second_index=j;
           second_max=U[i][j];
        }
 }
if (second_index == -1)
{
   for(int j=0;j<serverNum;j++)
 {
       if(j!=curServerIndex && CS[j] < minClients)
        {
           second_index=j;
           minClients=CS[j];
        }
 }
}
return second_index;
}


void serverScaleUpDown(Ptr<MyApp> app[total_client], Address sinkAddress[total_client], NodeContainer c)
{
        double data_rate=0;
        for(int i=0;i<serverNum;i++)
        {
                //cout<<"Capacity Before "<<i<<"= "<<Capacity[i]<<"\n";
                Capacity[i] = CS[i]; //propmotion (or demotion) of the server resources
                //cout<<"Capacity After "<<i<<"= "<<Capacity[i]<<"\n";
        }
        for(int i=0;i<total_client;i++)
        {
                //determine server bitrate
                data_rate = 2 - client[i].Type;
                std::stringstream sstm;
                sstm<<data_rate<<"Mbps";
                std::string result;
                result=sstm.str();
                //cout<<"Node "<<IC[i]<<": rate="<<result<<" Type ="<<client[i].Type<<"\n";         
                // Assign new bit rate for all       
                Ptr<Socket> ns3UdpSocket1 = Socket::CreateSocket (c.Get(US[i]), TcpSocketFactory::GetTypeId ()); //source at server
                // Create UDP application at server
                app[i]->StopStreaming();
                int packetSize=1448;
                app[i]->Setup (ns3UdpSocket1, sinkAddress[i], packetSize, 1000000, DataRate (result));
                c.Get(US[i])->AddApplication (app[i]);
                app[i]->StartStreaming();
         }
}

void
ChangeSocket(Ptr<MyApp> app, Address sinkAddress , int index, NodeContainer c, DataRate rate)
{
  app->StopStreaming();
  Ptr<Socket> ns3UdpSocket = Socket::CreateSocket (c.Get (index), TcpSocketFactory::GetTypeId ()); //source at n5
  // Create UDP application at n1
  app->Setup (ns3UdpSocket, sinkAddress, 1448, 1000000, rate);
  c.Get (index)->AddApplication (app);
  app->StartStreaming();
  return;
}

void
ChangeServer(Ptr<MyApp> app[total_client], DataRate rate)
{
    for(int i=0;i<total_client;i++)
            app[i]->ChangeRate(rate);
    return;
}

void
ReduceBitRate(Ptr<MyApp> app, uint32_t packetSize)
{
    app->ChangePacketSize(packetSize);
    return;
}

void
IncRate (Ptr<MyApp> app, DataRate rate)
{
	app->ChangeRate(rate);
    return;
}

double ComputeTh(Ptr<PacketSink> sink, Ptr<MyApp> app, int clientIndex)
{
  double cur = 0;
  Time now = Simulator::Now (); 
  if (sink->GetTotalRx() > lastTotalRx[clientIndex])
  {
   cur = (sink->GetTotalRx()-lastTotalRx[clientIndex]) * (double) 8/ timeInterval /1000000;
  }else
  {
   cur = (sink->GetTotalRx()) * (double) 8/ timeInterval /1000000;
  }
  lastTotalRx[clientIndex] = sink->GetTotalRx();      

return cur;
}

double qoe_table(double Thr, int data_Type)
{
double qoe = 0;
      if(data_Type==0)
      {
          if(Thr>=1.80)
              {qoe=5;}
          else if(Thr<1.80 && Thr >=1.50)
              {qoe=4.5;}
          else if(Thr<1.50 && Thr >=1.25)
              {qoe=4;}
          else if(Thr<1.25 && Thr >=1.0)
              {qoe=3.5;}
          else
              {qoe=2;}
      }
      else
      {
          if(Thr>=0.9)
              {qoe=4;}
          else if(Thr<0.90 && Thr >=0.75)
              {qoe=3.5;}
          else if(Thr<0.75 && Thr >=0.5)
              {qoe=3.0;}
          else if(Thr<0.5 && Thr >=0.25)
              {qoe=2.5;}
          else
              {qoe=1;}
      }

      return qoe;
}

double UnsatisfiedAt20=0.0;
double SatisfiedAt20=0.0;
double UnsatisfiedAt40=0.0;
double SatisfiedAt40=0.0;
double UnsatisfiedAt60=0.0;
double SatisfiedAt60=0.0;
double UnsatisfiedAt80=0.0;
double SatisfiedAt80=0.0;
double Thr=0.0;
int node[total_client];
int QoE=0;
double QoE_test[total_client];
double QoE_overall=0.0;

void lcdScheme(Ptr<PacketSink> sink[total_client], Ptr<MyApp> apps[total_client], NodeContainer c, Address sinkAddresses[total_client])
{
  Time currentTime = Simulator::Now (); /* Return the simulator's virtual time. */
  int now=currentTime.GetSeconds();
  int totalDisrupt = 0;
  int index;
  int total_fail=0;
  std::cout<<"LCD Scheme\n";
  int affected_client=0;
  double avgQoE = 0;
  for(int i=0;i<serverNum;i++)
  {
        cout<<"server "<<i<<"= "<<CS[i]<<"\n";
  }
  for(int i=0;i<total_client;i++)
  {
        Thr=ComputeTh(sink[i],apps[i], i);
        double clientQoE = qoe_table(Thr, client[i].Type);
        avgQoE+=clientQoE;       
        if (client[i].Disrupt == 0){
         client[i].Disrupt = client[i].prevQoE > clientQoE ? 1:0;       
         totalDisrupt += client[i].prevQoE > clientQoE ? 1:0;
        }else
        {
          totalDisrupt ++;
        }
        globalDisrupt += client[i].prevQoE > clientQoE ? 1:0;
        client[i].prevQoE = clientQoE;
        

      if(clientQoE<qoeThresh)
      { 
        affected_client++;
        
        //cout<<"Affected client "<<IC[i]<<": rate="<<Thr<<" Mbps type="<<client[i].Type<<", client QoE="<<clientQoE<<"\n";
        // Bit rate reduction
        if(client[i].C==0) //&& qoe_table(Thr, 1-client[i].Type) >= qoeThresh)
        {
                cout<<"Affected client "<<IC[i]<<": rate="<<Thr<<" Mbps type="<<client[i].Type<<", client QoE="<<clientQoE<<">> for Client Adoptation\n";
                totalAdaptNum++;
        //determine server bitrate
                double data_rate = 1;
                data_rate = (data_rate < ((double)Capacity[IS[i]]*data_rate/(double)CS[IS[i]])) ? data_rate : ((double)Capacity[IS[i]]*data_rate/(double)CS[IS[i]]);
                data_rate = round(data_rate*100)/100;
                //cout<<"Node "<<i<<" "<<data_rate<<" Mbps"<<" Cap="<<Capacity[IS[i]]<<" # of clients="<<CS[IS[i]]<<"\n";
                std::stringstream sstm;
                sstm<<data_rate<<"Mbps";
                std::string result;
                result=sstm.str();
                Simulator::Schedule (Seconds(00.0), &IncRate, apps[i], DataRate(result));
                client[i].Type=1;
                client[i].C=1;
                total_fail=0;
                
        }
        // client migration
        else if(prevServer[i]!=-1 || (client[i].N==0 && serverNum > 1 && getSecondUMinClient(IC[i], IS[i]) != -1))
        {      
         
                totalAdaptNum++;
                if(prevServer[i]==-1)
                {                  
                   index = getSecondUMinClient(IC[i], IS[i]);
                   prevServer[i] = IS[i];
                   cout<<"Affected client "<<IC[i]<<": rate="<<Thr<<" Mbps type="<<client[i].Type<<", client QoE="<<clientQoE<<">> for Network Adoptation to Server="<<index<<"\n";
                }
                else
                {
                   //cout<<"Affected client "<<IC[i]<<": rate="<<Thr<<" Mbps type="<<client[i].Type<<", client QoE="<<clientQoE<<">> remove Network Adoptation\n";
                   index = prevServer[i];
                   prevServer[i] = -1;
                   cout<<"Affected client "<<IC[i]<<": rate="<<Thr<<" Mbps type="<<client[i].Type<<", client QoE="<<clientQoE<<">> remove Network Adoptation back to="<<index<<"\n";
                }                
                 int prevServerIndex = IS[i];
                 CS[IS[i]]--;//remove client from prev server and adjust counter
                 CS[index]++;//add client to new server and adjust counter
                 IS[i] = index;
                 US[i]=Servers[index];
                 //adjust streaming speeds on both servers w.r.t. its capacity after client migration
                 for (int s=0;s<total_client;s++)
                 {
                        if(IS[s]==index || IS[s] == prevServerIndex)
                        {
                        double data_rate = 2-client[s].Type;
                        data_rate = (data_rate < ((double)Capacity[IS[s]]*data_rate/(double)CS[IS[s]])) ? data_rate : ((double)Capacity[IS[s]]*data_rate/(double)CS[IS[s]]);
                        data_rate = round(data_rate*100)/100;
                        //cout<<"Node changed "<<s<<" "<<data_rate<<" Mbps"<<" Cap="<<Capacity[IS[s]]<<" # of clients="<<CS[IS[s]]<<"\n";
                        std::stringstream sstm;
                        sstm<<data_rate<<"Mbps";
                        std::string result;
                        result=sstm.str();
                        Simulator::Schedule (Seconds(00.0), &ChangeSocket, apps[s], sinkAddresses[s], index, c, DataRate(result));
                        }
                 }                
                //client[i].Type=0;
                client[i].N=1; //adoptation was done
                total_fail=0;
                /*
                 
                 IS[i]=index;
                 updateNumberClient();
                */
        }
        // Force bit rate reduction to one for all clients conntected to current client server
        else if(client[i].S==0)
        {
                cout<<"Affected client "<<IC[i]<<": rate="<<Thr<<" Mbps type="<<client[i].Type<<", client QoE="<<clientQoE<<">> for Server Adoptation\n";
                int serverID = IS[i];                
                totalAdaptNum++;
                for(int j=0;j<total_client;j++)
                {
                        if(IS[j]==serverID)
                        {
                               double data_rate = 1;
                               data_rate = (data_rate < ((double)Capacity[IS[j]]*data_rate/(double)CS[IS[j]])) ? data_rate : ((double)Capacity[IS[j]]*data_rate/(double)CS[IS[j]]);
                               data_rate = round(data_rate*100)/100;
                               //cout<<"Node "<<i<<" "<<data_rate<<" Mbps"<<" Cap="<<Capacity[IS[i]]<<" # of clients="<<CS[IS[i]]<<"\n";
                                std::stringstream sstm;
                                sstm<<data_rate<<"Mbps";
                                std::string result;
                                result=sstm.str();
                                Simulator::Schedule (Seconds(00.0), &IncRate, apps[j], DataRate(result));
                                client[j].S = 1;
                                client[j].Type=1;
                        }
                }
         }
         else{
           total_fail=1;
         }
       }
       else
       {
         prevServer[i]=-1; // new server worked 
       } 
    }
    double int_alpha_qoe = (1-((double)affected_client/(double)total_client));
    if(int_alpha_qoe<alpha_qoe&&total_fail==1)
    {
        cout<<"Resource Promotion or Demotion needed!\n";
        //Simulator::Schedule (Seconds(00.0), &serverScaleUpDown, apps, sinkAddresses, c);
        //total_fail=0;
    }

    double totalCost = 0;
    for(int j=0;j<serverNum;j++)
    {
        totalCost +=Capacity[j];
    }
         
    cout<<"Total avg client at "<<now<<"sec avgQoE="<<avgQoE/total_client<<" coverage="<<(1-((double)affected_client/(double)total_client))<<" disruptLvl="<<(double)totalDisrupt/(double)(total_client)<<" totalAdapt="<<totalAdaptNum<<" totalCost="<<totalCost<<" globalDisrupt="<<globalDisrupt<<"\n";
}

void BitRateScheme(Ptr<PacketSink> sink[total_client], Ptr<MyApp> apps[total_client], NodeContainer c, Address sinkAddresses[total_client])
{
  Time currentTime = Simulator::Now (); /* Return the simulator's virtual time. */
  int now=currentTime.GetSeconds();
  int totalDisrupt = 0;
  //int index;
  int total_fail=0;
  std::cout<<"Bit Rate Scheme\n";
  int affected_client=0;
  double avgQoE = 0;
  for(int i=0;i<serverNum;i++)
  {
        cout<<"server "<<i<<"= "<<CS[i]<<"\n";
  }
  for(int i=0;i<total_client;i++)
  {
        Thr=ComputeTh(sink[i],apps[i], i);
        double clientQoE = qoe_table(Thr, client[i].Type);
        avgQoE+=clientQoE;       
        if (client[i].Disrupt == 0){
         client[i].Disrupt = client[i].prevQoE > clientQoE ? 1:0;       
         totalDisrupt += client[i].prevQoE > clientQoE ? 1:0;
        }else
        {
          totalDisrupt ++;
        }
        globalDisrupt += client[i].prevQoE > clientQoE ? 1:0;
        client[i].prevQoE = clientQoE;
      if(clientQoE<qoeThresh)
      { 
        affected_client++;
        //cout<<"Affected client "<<IC[i]<<": rate="<<Thr<<" Mbps type="<<client[i].Type<<", client QoE="<<clientQoE<<"\n";
        // Bit rate reduction
        if(client[i].C==0) //&& qoe_table(Thr, 1-client[i].Type) >= qoeThresh)
        {
                cout<<"Affected client "<<IC[i]<<": rate="<<Thr<<" Mbps type="<<client[i].Type<<", client QoE="<<clientQoE<<">> for Bit Rate Reduction\n";
                totalAdaptNum++;
        //determine server bitrate
                double data_rate = 1;
                data_rate = (data_rate < ((double)Capacity[IS[i]]*data_rate/(double)CS[IS[i]])) ? data_rate : ((double)Capacity[IS[i]]*data_rate/(double)CS[IS[i]]);
                data_rate = round(data_rate*100)/100;
                //cout<<"Node "<<i<<" "<<data_rate<<" Mbps"<<" Cap="<<Capacity[IS[i]]<<" # of clients="<<CS[IS[i]]<<"\n";
                std::stringstream sstm;
                sstm<<data_rate<<"Mbps";
                std::string result;
                result=sstm.str();
                Simulator::Schedule (Seconds(00.0), &IncRate, apps[i], DataRate(result));
                client[i].Type=1;
                client[i].C=1;
                total_fail=0;
          }  
        }
    }
    double int_alpha_qoe = (1-((double)affected_client/(double)total_client));
    if(int_alpha_qoe<alpha_qoe&&total_fail==1)
    {
        cout<<"Resource Promotion/Demotion is Needed\n";
        //Simulator::Schedule (Seconds(00.0), &serverScaleUpDown, apps, sinkAddresses, c);
        //total_fail=0;
    }

    double totalCost = 0;
    for(int j=0;j<serverNum;j++)
    {
        totalCost +=Capacity[j];
    }
         
    cout<<"Total avg client at "<<now<<"sec avgQoE="<<avgQoE/total_client<<" coverage="<<(1-((double)affected_client/(double)total_client))<<" disruptLvl="<<(double)totalDisrupt/(double)(total_client)<<" totalAdapt="<<totalAdaptNum<<" totalCost="<<totalCost<<" globalDisrupt="<<globalDisrupt<<"\n";
}

void LBScheme(Ptr<PacketSink> sink[total_client], Ptr<MyApp> apps[total_client], NodeContainer c, Address sinkAddresses[total_client])
{
  Time currentTime = Simulator::Now (); /* Return the simulator's virtual time. */
  int now=currentTime.GetSeconds();
  int totalDisrupt = 0;
  int index;
  int total_fail=0;
  std::cout<<"Load Balancing Scheme\n";
  int affected_client=0;
  double avgQoE = 0;
  for(int i=0;i<serverNum;i++)
  {
        cout<<"server "<<i<<"= "<<CS[i]<<"\n";
  }
  for(int i=0;i<total_client;i++)
  {
        Thr=ComputeTh(sink[i],apps[i], i);
        double clientQoE = qoe_table(Thr, client[i].Type);
        avgQoE+=clientQoE;       
        if (client[i].Disrupt == 0){
         client[i].Disrupt = client[i].prevQoE > clientQoE ? 1:0;       
         totalDisrupt += client[i].prevQoE > clientQoE ? 1:0;
        }else
        {
          totalDisrupt ++;
        }
        globalDisrupt += client[i].prevQoE > clientQoE ? 1:0;
        client[i].prevQoE = clientQoE;

      if(clientQoE<qoeThresh)
      { 
        affected_client++;
        // load balancing
        if(client[i].N==0 && serverNum > 1)
        {      
         
                totalAdaptNum++;       
                index = getLBServer(IC[i], IS[i]);
                cout<<"Affected client "<<IC[i]<<": rate="<<Thr<<" Mbps type="<<client[i].Type<<", client QoE="<<clientQoE<<">> for LB to Server="<<index<<"\n";    
                 int prevServerIndex = IS[i];   
                 CS[IS[i]]--;//remove client from prev server and adjust counter
                 CS[index]++;//add client to new server and adjust counter
                 IS[i] = index;
                 US[i]=Servers[index];
                 //adjust streaming speeds on both servers w.r.t. its capacity after client migration
                 for (int s=0;s<total_client;s++)
                 {
                        if(IS[s]==index || IS[s] == prevServerIndex)
                        {
                        double data_rate = 2-client[s].Type;
                        data_rate = (data_rate < ((double)Capacity[IS[s]]*data_rate/(double)CS[IS[s]])) ? data_rate : ((double)Capacity[IS[s]]*data_rate/(double)CS[IS[s]]);
                        data_rate = round(data_rate*100)/100;
                        //cout<<"Node changed "<<s<<" "<<data_rate<<" Mbps"<<" Cap="<<Capacity[IS[s]]<<" # of clients="<<CS[IS[s]]<<"\n";
                        std::stringstream sstm;
                        sstm<<data_rate<<"Mbps";
                        std::string result;
                        result=sstm.str();
                        Simulator::Schedule (Seconds(00.0), &ChangeSocket, apps[s], sinkAddresses[s], index, c, DataRate(result));
                        }
                 }                
                client[i].N=1; //adoptation was done
                total_fail=0;
        }
       }
    }
    double int_alpha_qoe = (1-((double)affected_client/(double)total_client));
    if(int_alpha_qoe<alpha_qoe&&total_fail==1)
    {
        cout<<"Resource Promotion/Demotion is Needed\n";
        //Simulator::Schedule (Seconds(00.0), &serverScaleUpDown, apps, sinkAddresses, c);
        //total_fail=0;
    }

    double totalCost = 0;
    for(int j=0;j<serverNum;j++)
    {
        totalCost +=Capacity[j];
    }
         
    cout<<"Total avg client at "<<now<<"sec avgQoE="<<avgQoE/total_client<<" coverage="<<(1-((double)affected_client/(double)total_client))<<" disruptLvl="<<(double)totalDisrupt/(double)(total_client)<<" totalAdapt="<<totalAdaptNum<<" totalCost="<<totalCost<<" globalDisrupt="<<globalDisrupt<<"\n";
}

//Client Migration
void CMScheme(Ptr<PacketSink> sink[total_client], Ptr<MyApp> apps[total_client], NodeContainer c, Address sinkAddresses[total_client])
{
  Time currentTime = Simulator::Now (); /* Return the simulator's virtual time. */
  int now=currentTime.GetSeconds();
  int totalDisrupt = 0;
  int index;
  int total_fail=0;
  std::cout<<"Client Migration Scheme\n";
  int affected_client=0;
  double avgQoE = 0;
  for(int i=0;i<serverNum;i++)
  {
        cout<<"server "<<i<<"= "<<CS[i]<<"\n";
  }
  for(int i=0;i<total_client;i++)
  {
        Thr=ComputeTh(sink[i],apps[i], i);
        double clientQoE = qoe_table(Thr, client[i].Type);
        avgQoE+=clientQoE;       
        if (client[i].Disrupt == 0){
         client[i].Disrupt = client[i].prevQoE > clientQoE ? 1:0;       
         totalDisrupt += client[i].prevQoE > clientQoE ? 1:0;
        }else
        {
          totalDisrupt ++;
        }
        globalDisrupt += client[i].prevQoE > clientQoE ? 1:0;
        client[i].prevQoE = clientQoE;

      if(clientQoE<qoeThresh)
      { 
        affected_client++;
        // client migration
        if(prevServer[i]!=-1 || (client[i].N==0 && serverNum > 1 && getSecondUMinClient(IC[i], IS[i]) != -1))
        {      
         
                totalAdaptNum++;
                if(prevServer[i]==-1)
                {                  
                   index = getSecondUMinClient(IC[i], IS[i]);
                   prevServer[i] = IS[i];
                   cout<<"Affected client "<<IC[i]<<": rate="<<Thr<<" Mbps type="<<client[i].Type<<", client QoE="<<clientQoE<<">> for Client Migration to Server="<<index<<"\n";
                }
                else
                {
                   //cout<<"Affected client "<<IC[i]<<": rate="<<Thr<<" Mbps type="<<client[i].Type<<", client QoE="<<clientQoE<<">> remove Network Adoptation\n";
                   index = prevServer[i];
                   prevServer[i] = -1;
                   cout<<"Affected client "<<IC[i]<<": rate="<<Thr<<" Mbps type="<<client[i].Type<<", client QoE="<<clientQoE<<">> returb Client Back to Server="<<index<<"\n";
                }                
                 int prevServerIndex = IS[i];
                 CS[IS[i]]--;//remove client from prev server and adjust counter
                 CS[index]++;//add client to new server and adjust counter
                 IS[i] = index;
                 US[i]=Servers[index];
                 //adjust streaming speeds on both servers w.r.t. its capacity after client migration
                 for (int s=0;s<total_client;s++)
                 {
                        if(IS[s]==index || IS[s] == prevServerIndex)
                        {
                        double data_rate = 2-client[s].Type;
                        data_rate = (data_rate < ((double)Capacity[IS[s]]*data_rate/(double)CS[IS[s]])) ? data_rate : ((double)Capacity[IS[s]]*data_rate/(double)CS[IS[s]]);
                        data_rate = round(data_rate*100)/100;
                        //cout<<"Node changed "<<s<<" "<<data_rate<<" Mbps"<<" Cap="<<Capacity[IS[s]]<<" # of clients="<<CS[IS[s]]<<"\n";
                        std::stringstream sstm;
                        sstm<<data_rate<<"Mbps";
                        std::string result;
                        result=sstm.str();
                        Simulator::Schedule (Seconds(00.0), &ChangeSocket, apps[s], sinkAddresses[s], index, c, DataRate(result));
                        }
                 }                
                //client[i].Type=0;
                client[i].N=1; //adoptation was done
                total_fail=0;
                /*
                 IS[i]=index;
                 updateNumberClient();
                */
        }
       }
       else
       {
         prevServer[i]=-1; // new server worked 
       } 
    }
    double int_alpha_qoe = (1-((double)affected_client/(double)total_client));
    if(int_alpha_qoe<alpha_qoe&&total_fail==1)
    {
        cout<<"Resource Promotion/Demotion is Needed\n";
        //Simulator::Schedule (Seconds(00.0), &serverScaleUpDown, apps, sinkAddresses, c);
        //total_fail=0;
    }

    double totalCost = 0;
    for(int j=0;j<serverNum;j++)
    {
        totalCost +=Capacity[j];
    }
         
    cout<<"Total avg client at "<<now<<"sec avgQoE="<<avgQoE/total_client<<" coverage="<<(1-((double)affected_client/(double)total_client))<<" disruptLvl="<<(double)totalDisrupt/(double)(total_client)<<" totalAdapt="<<totalAdaptNum<<" totalCost="<<totalCost<<" globalDisrupt="<<globalDisrupt<<"\n";
}

// Bit rate adaptation on Server
void AMP_SMP_Scheme(Ptr<PacketSink> sink[total_client], Ptr<MyApp> apps[total_client], NodeContainer c, Address sinkAddresses[total_client])
{
  Time currentTime = Simulator::Now (); /* Return the simulator's virtual time. */
  int now=currentTime.GetSeconds();
  int totalDisrupt = 0;
  int total_fail=0;
  std::cout<<"AMP-SMP Scheme\n";
  int affected_client=0;
  double avgQoE = 0;
  for(int i=0;i<serverNum;i++)
  {
        cout<<"server "<<i<<"= "<<CS[i]<<"\n";
  }
  for(int i=0;i<total_client;i++)
  {
        Thr=ComputeTh(sink[i],apps[i], i);
        double clientQoE = qoe_table(Thr, client[i].Type);
        avgQoE+=clientQoE;       
        if (client[i].Disrupt == 0){
         client[i].Disrupt = client[i].prevQoE > clientQoE ? 1:0;       
         totalDisrupt += client[i].prevQoE > clientQoE ? 1:0;
        }else
        {
          totalDisrupt ++;
        }
        globalDisrupt += client[i].prevQoE > clientQoE ? 1:0;
        client[i].prevQoE = clientQoE;

      if(clientQoE<qoeThresh)
      { 
        affected_client++;
        // Force bit rate reduction to one for all clients conntected to current client server
        if(client[i].S==0)
        {
                cout<<"Affected client "<<IC[i]<<": rate="<<Thr<<" Mbps type="<<client[i].Type<<", client QoE="<<clientQoE<<">> for Server Bit Rate Reduction\n";
                int serverID = IS[i];                
                totalAdaptNum++;
                for(int j=0;j<total_client;j++)
                {
                        if(IS[j]==serverID)
                        {
                               double data_rate = 1;
                               data_rate = (data_rate < ((double)Capacity[IS[j]]*data_rate/(double)CS[IS[j]])) ? data_rate : ((double)Capacity[IS[j]]*data_rate/(double)CS[IS[j]]);
                               data_rate = round(data_rate*100)/100;
                               //cout<<"Node "<<i<<" "<<data_rate<<" Mbps"<<" Cap="<<Capacity[IS[i]]<<" # of clients="<<CS[IS[i]]<<"\n";
                                std::stringstream sstm;
                                sstm<<data_rate<<"Mbps";
                                std::string result;
                                result=sstm.str();
                                Simulator::Schedule (Seconds(00.0), &IncRate, apps[j], DataRate(result));
                                client[j].S = 1;
                                client[j].Type=1;
                        }
                }
         }
       }
    }
    double int_alpha_qoe = (1-((double)affected_client/(double)total_client));
    if(int_alpha_qoe<alpha_qoe&&total_fail==1)
    {
        cout<<"Resource Promotion/Demotion is Needed\n";
        //Simulator::Schedule (Seconds(00.0), &serverScaleUpDown, apps, sinkAddresses, c);
        //total_fail=0;
    }

    double totalCost = 0;
    for(int j=0;j<serverNum;j++)
    {
        totalCost +=Capacity[j];
    }
         
    cout<<"Total avg client at "<<now<<"sec avgQoE="<<avgQoE/total_client<<" coverage="<<(1-((double)affected_client/(double)total_client))<<" disruptLvl="<<(double)totalDisrupt/(double)(total_client)<<" totalAdapt="<<totalAdaptNum<<" totalCost="<<totalCost<<" globalDisrupt="<<globalDisrupt<<"\n";
}

int
main (int argc, char *argv[])
{
  readFromFile(); //Uncomment this when read PCM file
  srand(time(0));
  int packetSize;
  LogComponentEnable ("UdpEchoClientApplication", LOG_LEVEL_ALL);
  LogComponentEnable ("UdpEchoServerApplication", LOG_LEVEL_ALL);

  LogComponentEnable ("BriteExample", LOG_LEVEL_ALL);

  // BRITE needs a configuration file to build its graph. By default, this
  // example will use the TD_ASBarabasi_RTWaxman.conf file. There are many others
  // which can be found in the BRITE/conf_files directory
  bool tracing = false;

  CommandLine cmd;
  cmd.AddValue ("confFile", "BRITE conf file", confFile);
  cmd.AddValue ("tracing", "Enable or disable ascii tracing", tracing);

  cmd.Parse (argc,argv);

  // Invoke the BriteTopologyHelper and pass in a BRITE
  // configuration file and a seed file. This will use
  // BRITE to build a graph from which we can build the ns-3 topology
  BriteTopologyHelper bth (confFile,"seed_file","new_seed_file");
  bth.AssignStreams (3);

  PointToPointHelper p2p;

  InternetStackHelper stack;

  Ipv4AddressHelper address;
  address.SetBase ("10.0.0.0", "255.255.255.252");

  bth.BuildBriteTopology (stack);
  bth.AssignIpv4Addresses (address);
    
  NodeContainer c = bth.m_nodes;

  uint16_t sinkPort = 6; // use the same for all apps
  uint32_t numPackets = 1000000000;
  Address sinkAddresses[total_client];
  Ptr<MyApp> apps[total_client];
  Ptr<PacketSink> sink[total_client];
  
  int k=0;
  for(int i=0;i<N;i++)
  {
     int index=0;   
     double max_value=0;
     // assign client to a server based on assignment probabilities
     for(int j=0;j<serverNum;j++)//N-total_client
     {
        if(U[i][j]>max_value)
        {
           index=j;
           max_value=U[i][j];
        }
     }     
     if(Servers[index]==i)
        {continue;}
     else
        { 
          if(max_value==0)
          {index=rand()%serverNum;}
          //Count # of clients connected to each server
          US[k]=Servers[index];
          IS[k]=index;
          IC[k]=i;
          CS[index]++;  
          //cout<<i<<": IS "<<k<<"="<<IS[k]<<" of"<<" CS "<<index<<"="<<CS[index]<<" for server id="<<Servers[index]<<"\n";
          k++;
        }
  }
    
 // add capacity and print server properties
    for(int j=0;j<serverNum;j++)
    {
        Capacity[j] = sCap; //# of clients per server
        cout<<"Server["<<Servers[j]<<"] ("<<j<<" out of "<<serverNum<<") capacity="<<Capacity[j]<<"\n";
    }

 for(int i=0;i<total_client;i++)
  {   
        // UDP connection from Server to Client
        Ptr<Ipv4> ipv41 = bth.GetNodeForAs(0,IC[i])->GetObject<Ipv4>();
        Ipv4InterfaceAddress iaddr1 = ipv41->GetAddress (1,0);
        Ipv4Address addri1 = iaddr1.GetLocal ();
        Address sinkAddress1 (InetSocketAddress (addri1, sinkPort)); // interface of receiver
        PacketSinkHelper packetSinkHelper1 ("ns3::TcpSocketFactory", InetSocketAddress (Ipv4Address::GetAny (), sinkPort));
        ApplicationContainer sinkApps1 = packetSinkHelper1.Install (bth.GetNodeForAs(0,IC[i])); //client as sink
        sinkApps1.Start (Seconds (0.));
        sinkApps1.Stop (Seconds (totalTime));

        Ptr<Socket> ns3UdpSocket1 = Socket::CreateSocket (bth.GetNodeForAs(0,US[i]), TcpSocketFactory::GetTypeId ()); //source at server
        // Create UDP application at server
        Ptr<MyApp> app = CreateObject<MyApp> ();
        packetSize=1448;
        
        //determine server bitrate
        double data_rate = 2;
        data_rate = (data_rate < ((double)Capacity[IS[i]]*data_rate/(double)CS[IS[i]])) ? data_rate : ((double)Capacity[IS[i]]*data_rate/(double)CS[IS[i]]);
        data_rate = round(data_rate*100)/100;
        //cout<<"Node "<<US[i]<<" "<<data_rate<<" Mbps"<<" Cap="<<Capacity[IS[i]]<<" # of clients="<<CS[IS[i]]<<" server's index= "<<IS[i]<<"\n";
        std::stringstream sstm;
        sstm<<data_rate<<"Mbps";
        std::string result;
        result=sstm.str();
        cout<<"Node["<<IC[i]<<"] ("<<i<<" out of "<<total_client<<"): rate="<<result<<"\n";
        app->Setup (ns3UdpSocket1, sinkAddress1, packetSize, numPackets, DataRate (result));
        c.Get(US[i])->AddApplication (app);
        app->SetStartTime (Seconds (10.));
        app->SetStopTime (Seconds (totalTime));
        
        //put all into array
        client[i].C=0;
        client[i].N=0;
        client[i].S=0;
        client[i].Type=0;
        client[i].Disrupt=0;
        client[i].prevQoE=0;
        sinkAddresses[i]=sinkAddress1;
        apps[i]=app;
        sink[i] = StaticCast<PacketSink> (sinkApps1.Get (0));
        //setup previously used server as NaN
        prevServer[i]=-1;
  }
   
  Ipv4GlobalRoutingHelper::PopulateRoutingTables ();
    
  //Save topo
  bth.SaveBriteTopo(topoName);    

  for(int i=1;i<=(totalTime-10)/timeInterval;i++)
  {
        if (schemeType == 0)
        {
              Simulator::Schedule (Seconds(10.0+i*timeInterval), &lcdScheme, sink,apps,c,sinkAddresses);
        }
        else if (schemeType == 1)
        {
              Simulator::Schedule (Seconds(10.0+i*timeInterval), &BitRateScheme, sink,apps,c,sinkAddresses);
        }
        else if (schemeType == 2)
        {
              Simulator::Schedule (Seconds(10.0+i*timeInterval), &LBScheme, sink, apps, c, sinkAddresses);
        }
        else if (schemeType == 3)
        {
              Simulator::Schedule (Seconds(10.0+i*timeInterval), &CMScheme, sink, apps, c, sinkAddresses);
        } 
        else if (schemeType == 4)
        {
              Simulator::Schedule (Seconds(10.0+i*timeInterval), &AMP_SMP_Scheme, sink, apps, c, sinkAddresses);
        }
 }

  // Run the simulator
  Simulator::Stop (Seconds (totalTime));
  Simulator::Run ();
  Simulator::Destroy ();
  NS_LOG_INFO("DONE.");
  return 0;
}
