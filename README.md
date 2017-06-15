# |QoE-oriented Cloud Service Orchestration 
# |for Application Providers

In this project, we address the general Application Service Provider (ASP) optimization problem — maximization of the
satisfactory QoE service delivery to users with limited by the ASP’s cost budget. We split this problem into the ASP 'management plane' and the 'data plane' optimization sub-problems, respectively. 

* We address the problem of service placement in the ASP 'management plane' (when application services are being deployed and are not yet operational) to maximize Service Level Objective (SLO) coverage of users by using its optimal solution with integer linear programming (ILP). 
To further avoid ILP NP-hardness, we also devise a heuristic algorithm for the management plane problem, which is based on a novel Possibilistic C-Means (PCM) infrastructure clustering algorithm that takes into account multiple SLO path constraints. 

* To address intractabilities for the ASP 'data plane' optimization (applications services are operational with real user access) that enhances satisfactory user QoE delivery, we devise a model that captures dynamics in the interplay between the three Q’s i.e., infrastructure Quality of Service (QoS) and user-side Quality of Application (QoA) that cater to the user QoE (3Q). We use a heuristic algorithm that leverages a Least-Cost Disruptive (LCD) decision tree that manages
our 3Q interplay model to decide on suitable adaptations for handling trade-offs between (a) satisfactory user QoE delivery, (b) cost of adaptations, and (c) user disruption level factors caused by these adaptations.


Authors
=================
2017 VIMAN laboratory, Computer Science Department, University of Missouri-Columbia.

```
Updated June 15, 2017 by Dmitrii Chemodanov
```

All feedback appreciated to dycbt4@mail.missouri.edu 

License
=================
This project is licensed under the GNU General Public License - see the [LICENSE.md](LICENSE.md) file for details


What is inside?
================
The source code for the ACM TOMM submission (SI on QoE Management for Multimedia Services) 
titled: "On QoE-oriented Cloud Service Orchestration for Application Providers"

Matlab simulation is used to evalute the Application Service Provider (ASP) mangement plane optimization solutions
NS-3 simulation is used to evalute the ASP data plane optimization solutions

Distribution
================
The distribution tree contains: 

* README

	- this file
    
* matlab_sim/ (source files for the ASP management plane optimization problem)	

    ```
    maim_tomm.m       (main file for the clustering-based ASP optimization solution)

    main_tomm_opt.m   (main file for the integer linear programming based ASP optimization solution)
    ```
    
* ns3_sim/ (source files for the ASP data plane optimization problem)

    - BRITE/   (source files for the Brite topology generator that is used to generate realistic Internet topologies)
    
    - ns-3.25/ (source files for the ASP data plane optimization evaluation)
    
        - *.m      (matlab source files from the ASP mangement optimization, that are used for service deployment)
        
        - scratch/ (c++ source files for the ASP data plane simulation and optimization)
        
            ```
            lcd_simulation_ns3.cc (main file for the ASP data plane simulation and optimization)
            ```