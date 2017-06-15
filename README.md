Title
=================
QoE-oriented Cloud Service Orchestration

Authors
=================
2017 VIMAN laboratory, Computer Science Department, University of Missouri-Columbia.

```
Updated June 14, 2017 by Dmitrii Chemodanov
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