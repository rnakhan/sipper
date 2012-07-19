#include <unistd.h>
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <netinet/in.h>
#include <sys/socket.h>
#include <arpa/inet.h>
#include <fcntl.h>

int main(int argc, char **argv)
{
   if(argc != 4)
   {
      printf("Usage: %s <MsgFilename> <TargetIP> <TargetPort>\n", argv[0]);
      return 1;
   }

   char buffer[10000];
   struct stat filestat;

   if(stat(argv[1], &filestat) < 0)
   {
      printf("Error getting filestat.\n");
      return 1;
   };
   int fd = open(argv[1], O_RDONLY, 0644);
   read(fd, buffer, filestat.st_size);
   close(fd);


   int sock = socket(AF_INET, SOCK_DGRAM, 0);

   struct sockaddr_in sendTarget;
   memset(&sendTarget, 0, sizeof(sendTarget));
   sendTarget.sin_family = AF_INET;
   sendTarget.sin_port = htons((short)atoi(argv[3]));
   sendTarget.sin_addr.s_addr = inet_addr(argv[2]);

   sendto(sock, buffer, filestat.st_size, 0, 
          (struct sockaddr *)&sendTarget,
          sizeof(sockaddr_in));

}
