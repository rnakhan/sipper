// MediaConsole.cpp : Defines the entry point for the console application.
//

#ifndef __UNIX__
#include "stdafx.h"
#endif
#include "pthread.h"
#include <string>

#ifndef __UNIX__
#include <winsock2.h>
#include <ws2tcpip.h>
#else
#include <errno.h>
#include <unistd.h>
#include <fcntl.h>
#include <sys/types.h>
#include <time.h>
#include <sys/time.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <netinet/tcp.h>
#include <arpa/inet.h>

#endif

bool _shutdownFlag = false;

int getErrorCode()
{
#ifdef __UNIX__
	return errno;
#else
	return WSAGetLastError();
#endif
}

std::string errorString()
{
	std::string ret = (const char *) strerror(getErrorCode());
	return ret;
}

void setNonBlocking(int fd)
{
#ifdef __UNIX__
   int flags;

   if((flags = fcntl(fd, F_GETFL, 0)) < 0)
   {
	  std::string errMsg = errorString();

      printf("Error getting socket status. [%s]\n",
             errMsg.c_str());

      exit(1);
   }

   flags |= O_NONBLOCK;

   if(fcntl(fd, F_SETFL, flags) < 0)
   {
	  std::string errMsg = errorString();

      printf("Error setting nonBlocking. [%s]\n",
             errMsg.c_str());

      exit(1);
   }
#else
   unsigned long flag = 1;
   if(ioctlsocket(fd, FIONBIO, &flag) != 0)
   {
	  std::string errMsg = errorString();

      printf("Error setting nonBlocking. [%s]\n",
             errMsg.c_str());

      exit(1);
   }
#endif
}

void disconnectSocket(int &fd)
{
	if(fd != -1)
	{
#ifdef __UNIX__
		close(fd);
#else
		closesocket(fd);
#endif
		fd = -1;
	}
}

void setTcpNoDelay(int fd)
{
   int flag = 1;
#ifdef __UNIX__
   if(setsockopt(fd, IPPROTO_TCP, TCP_NODELAY, &flag, sizeof(int)) < 0)
#else
   if(setsockopt(fd, IPPROTO_TCP, TCP_NODELAY, (const char *)&flag, sizeof(int)) < 0)
#endif
   {
	  std::string errMsg = errorString();

      printf("Error disabling Nagle algorithm. [%s]\n",
             errMsg.c_str());

      exit(1);
   }

   printf("Successfully changed the Sock[%d] options.\n",
          fd);
}

int sendSocket(int sock, const void *indata, unsigned int toSend)
{
   int retVal = 0;

   fd_set write_fds;  
   char *buf = (char *)indata;

   while(toSend)
   {
      retVal = send(sock, buf, toSend, 0);

	  if(retVal >= 0)
	  {
		  buf += retVal;
		  toSend -= retVal;
		  continue;
	  }

	  switch(getErrorCode())
	  {
#ifdef __UNIX__
		case EINTR:
#else
		case WSAEINTR:
#endif
		{
            printf("Send interrupted. [%d] Msg[%s].\n",
				sock, strerror(getErrorCode()));
		    continue;
		}
#ifdef __UNIX__
		case EAGAIN:
#else
		case WSAEWOULDBLOCK:
#endif
		{
		}
		break;

		default:
		{
			printf("Error in sending [%d] Msg[%s].\n",
				sock, strerror(getErrorCode()));
			return -1;
		}
	  }
         
      FD_ZERO(&write_fds);  FD_SET(sock, &write_fds);

      struct timeval time_out;

      time_out.tv_sec = 5;
      time_out.tv_usec = 0;

      printf("Waiting for buffer clearup. Sock[%d].\n",
             sock);

      retVal = select(sock + 1, NULL, &write_fds, NULL, &time_out);

      if(retVal == 0)
      {
		 printf("Write select timedout.\n");
         return -1;
      }
   }

   return 0;
}

int readSocket(int sock, void *buf, unsigned int toRead)
{
   char *addr = (char *)buf;
   unsigned int dataRead = 0;

   int retVal = 0;

   fd_set read_fds;  

   while(toRead)
   {
      retVal = recv(sock, addr, toRead, 0);

      if(retVal == 0)
      {
	     printf("Recv returned zero for[%d].\n", sock);
         return -1;
      }
      else if(retVal > 0)
      {
         dataRead += retVal;
         toRead -= retVal;

         if(toRead == 0)
         {
            return 0;
         }
         else
         {
            addr += retVal;
         }

         continue;
      }
      else
      {
		 switch(getErrorCode())
         {
#ifdef __UNIX__
            case EINTR:
#else
			case WSAEINTR:
#endif
            {
               printf("Recv interrupted for [%d]. [%s]\n", 
					   sock, strerror(getErrorCode()));
            }
            break;

#ifdef __UNIX__
            case EWOULDBLOCK:
#else
			case WSAEWOULDBLOCK:
#endif
            {
            }
            break;

            default:
            {
               printf("Recv failed for [%d]. [%s]\n", 
				   sock, strerror(getErrorCode()));
               return -1;
            }
         }
      }

      while(true)
      {
         FD_ZERO(&read_fds);  FD_SET(sock, &read_fds);

         struct timeval time_out;
         time_out.tv_sec = 5;
         time_out.tv_usec = 0;

         retVal = select(sock + 1, &read_fds, NULL, NULL, &time_out);

         if((retVal == -1) && (errno == EINTR))
         {
            printf("Select for [%d] interrupted. [%s]\n", 
				sock, strerror(getErrorCode()));
            continue;
         }

         break;
      }

      if(retVal == 0)
      {
		 printf("Error reading command completly. Read[%d] ToRead[%d].\n", dataRead, toRead);
         return -1;
      }

      if(retVal == -1)
      {
         printf("Select failed for [%d]. [%s]\n", 
			 sock, strerror(getErrorCode()));
         return -1;
      }
   }

   return 0;
}


extern "C" void * _readerThread(void *data)
{
   pthread_detach(pthread_self());
   int *thrData = (int *)data;
   int sock = *thrData;
   delete thrData;

   fd_set read_fds;

   while(true)
   {
      FD_ZERO(&read_fds);
      FD_SET(sock, &read_fds);

	  struct timeval time_out;
	  time_out.tv_sec = 1;
	  time_out.tv_usec = 0;

	  if(select(sock + 1, &read_fds, NULL, NULL, &time_out) == -1)
	  {
		  std::string errMsg = errorString();
		  printf("Error getting socket status. [%s]\n",
				 errMsg.c_str());
		  continue;
	  }

	  if(FD_ISSET(sock, &read_fds))
	  {
		  int len = 0;
		  if(readSocket(sock, &len, 4) == -1)
		  {
			  _shutdownFlag = true;
#ifndef __UNIX__
			  exit(0);
#endif
			  return NULL;
		  }
		  len = ntohl(len);

		  char *event = new char[len + 1];
		  event[len] = '\0';
		  if(readSocket(sock, event, len) == -1)
		  {
			  delete []event;
			  _shutdownFlag = true;
#ifndef __UNIX__
			  exit(0);
#endif
			  return NULL;
		  }

		  printf("Recv: [%s]\n", event);
		  delete []event;
	  }
   }
}

int main(int argc, char* argv[])
{
	if(argc != 3)
	{
		printf("Usage error. %s <IP> <Port>\n", argv[0]);
		return 1;
	}

#ifndef __UNIX__
   WSADATA wsaData;
   int iResult;

   iResult = WSAStartup(MAKEWORD(2,2), &wsaData);
   if (iResult != 0) 
   {
      printf("WSAStartup failed: %d\n", iResult);
      exit(1);
   }
#endif

   int sock = socket(AF_INET, SOCK_STREAM, 0);
   short port = atoi(argv[2]);

   u_int flagOn = 1;

   sockaddr_in svrInfo;
   memset(&svrInfo, 0, sizeof(sockaddr_in));

   svrInfo.sin_family = AF_INET;
   svrInfo.sin_addr.s_addr = inet_addr(argv[1]);
   svrInfo.sin_port = htons(port);

   if(connect(sock, (struct sockaddr *)&svrInfo, sizeof(sockaddr_in)) == -1)
   {
      printf("Unable to connect to Port[%d] Error[%s].\n",
             port, errorString().c_str());
	  disconnectSocket(sock);
      return -1;
   }

   setNonBlocking(sock);
   setTcpNoDelay(sock);

   int *thrdata = new int;
   *thrdata = sock;
   
   pthread_t reader;
   pthread_create(&reader, NULL, _readerThread, thrdata);

   while(!_shutdownFlag)
   {
#ifdef __UNIX__
	  fd_set read_fds;

	  FD_ZERO(&read_fds);
      FD_SET(0, &read_fds);

	  struct timeval time_out;
	  time_out.tv_sec = 0;
	  time_out.tv_usec = 100000;

	  if(select(1, &read_fds, NULL, NULL, &time_out) == -1)
	  {	  
		  std::string errMsg = errorString();
		  printf("Error getting socket status. [%s]\n",
			     errMsg.c_str());			
		  continue;	  
	  }

	  if(!FD_ISSET(0, &read_fds))
	  {
		  continue;
	  }
#endif
	  char command[8000];
	  memset(command, 0, 8000);
	  fgets(command, 7999, stdin);

	  int len = strlen(command);
	  command[len - 1] = '\0';
	  len--;
	  int newlen = htonl(len);
	  if(sendSocket(sock, &newlen, 4) == -1)
	  {
		  exit(0);
	  }
	  
	  if(sendSocket(sock, command, len) == -1)
	  {
		  exit(0);
	  }
   }

   return 0;
}

