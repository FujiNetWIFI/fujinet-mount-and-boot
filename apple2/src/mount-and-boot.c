/**
 * Mount and boot 
 *
 * @author  Thomas Cherryhomes
 * @email   thom dot cherryhomes at gmail dot com
 * @license gpl v. 3
 */

#include <stdbool.h>
#include <apple2.h>
#include <conio.h>
#include <peekpoke.h>
#include "sp.h"

#define FUJICMD_SET_BOOT_MODE 0xD6
#define FUJICMD_MOUNT_ALL     0xD7

#define BOOT_MODE_CONFIG      0x00

unsigned long timer = 32768UL;
unsigned char fuji;

void boot(void)
{
  char ostype;

  ostype = get_ostype() & 0xF0;
  cputs("BOOTING...\r\n");

  if (ostype == APPLE_IIIEM)
  {
    asm("STA $C082");  // disable language card (Titan3+2)
    asm("LDA #$77");   // enable A3 primary rom
    asm("STA $FFDF");
    asm("JMP $F4EE");  // jmp to A3 reset entry
  }
  else  // Massive brute force hack that takes advantage of MMU quirk. Thank you xot.
  {
    POKE(0x100,0xEE);
    POKE(0x101,0xF4);
    POKE(0x102,0x03);
    POKE(0x103,0x78);
    POKE(0x104,0xAD);
    POKE(0x105,0x82);
    POKE(0x106,0xC0);
    POKE(0x107,0x6C);
    POKE(0x108,0xFC);
    POKE(0x109,0xFF);

    asm("JMP $0100");
  }

}

void mount_all(void)
{
  cputs("MOUNTING ALL DEVICES\r\n");
  sp_control(fuji,FUJICMD_MOUNT_ALL);
}

void mount_config(void)
{
  cputs("MOUNTING CONFIG\r\n");

  sp_payload[0] = 1;
  sp_payload[1] = 0;
  sp_payload[2] = BOOT_MODE_CONFIG;
  
  sp_control(fuji,FUJICMD_SET_BOOT_MODE);
}

bool waitkey(void)
{
  char c;
  
  while (timer > 0)
    {
      c = kbhit();
      
      if (c)
	break;
      else
	timer--;
    }

  return c;
}

void main(void)
{
  clrscr();

  sp_init();
  fuji = sp_find_fuji();
  
  cputs("PRESS ANY KEY TO GO TO CONFIG\r\n");
  cputs("OR WAIT TO MOUNT AND BOOT...");

  if (waitkey())
    mount_config();
  else
    mount_all();

  boot();
}
