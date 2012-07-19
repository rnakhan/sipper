           
            MWI            Subscriber       VM          X-lite (non-subscriber     X-lite(subscriber with name "123") 
                                                        name other than "123")

             |                |              |                   |                   |
             |  subscribe     |              |                   |                   |
             |<---------------|              |                   |		     | 	
             |                |              |                   |                   |  
             |   notify       | Monitoring for                   |                   |
             |--------------->|	voicemail    |                   |                   |
             |                |<------------>|  Leaves a msg     |                   | 
             |                |              |  to subscriber    |                   |
             |                |              |<------------------|                   |  
             |                |              |                   |                   |
             |                |              |                   |                   |
             |    notify      |              |                   |                   |
             |--------------->|              |                   |                   |
             |                |              |                   |                   | 
             |                |              |                   |                   |
             |                |              |        listen the recorded msg        |    
             |                |              |<--------------------------------------| 
             |                |              |                   |                   |
             |                |              |                   |                   |
            

Purpose of the Application:
----------------------------

A controller called vm_controller, that acts as a UAS. On INVITE it plays a message "The subscriber is not available, please leave a message after the tone". Then it plays a beep. After that it records the message by the caller. This recorded file is placed in file system (or in a MySQL database). There is another controller that has received MWI subscription for the subscriber and is periodically monitoring the file system (or DB). On seeing a message it sends a MWI NOTIFY to the subscriber. When the subscriber calls the vm_controller, the controller connects the call and says "you have a new voice mail to hear it press 1". When user presses 1 the vm_controller plays the recorded VM.


Procedure to run:
------------------

1. Run the MWI controller:

   “srun  -i 127.0.0.1 –p 5068 –c mwicontroller.rb”


2. Run the subscriber which sends the subscribe message to the MWI controller. MWI controller replies with the notify message and starts monitoring the     voicemail . And if any voicemail comes for the subscriber, it send the notify message to the subscriber that there is new voicemail to you. To run the  subscriber test, open a new command shell and run the following command:  

   “srun –i 127.0.0.1 –p 5065 –r 127.0.0.1 –o 5068 –t testsubscriber.rb”


3. Run the VM controller that acts as a UAS. On INVITE it plays a message "The subscriber is not available, please leave a message after the tone".
To play this, file used is "welcome.au" in the script, which should be placed under current directory. After that it records the message by the caller.      This recorded file is placed in the mailbox directory under the current path, so directory named "mailbox" should be manually created at the current path. It is assumed that the subscriber name is "123", so if any subscriber having the different name from “123”, VM controller records its message else it plays "greeting.au" which says "you have a new voice mail to hear it press 1". Again this file should be placed under the current directory. Then after pressing 1, it plays the recorded message to the subscriber if any. To run the vmcontroller, open a new command shell and run the following command:

   “srun –i 127.0.0.1 –p 5067 –c vmcontroller”  

4. To record the message, use x-lite software with name other than "123" and make a call to Vm-controller which is running on port 5067. To listen recorded   message make a another call with name "123" and press 1 to hear the recorded message.


In the above mentioned example, one can use the desired IP and Ports.    