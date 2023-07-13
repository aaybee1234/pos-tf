IAAC example for deploying a new VPC consisting of two private subnets and two public. 
We used deenseth PHP-Point-Of-Sale code for this example. A database server will be created using the ami that i set up before and will be connected with our apache webservers through private connection. These webservers are configured with an autoscaling group that scales up incase the load or number of users in goes up. WE also have a load balancer that monitors the load and security of the app. 

You can view the detailed configuration in pos.tf file
