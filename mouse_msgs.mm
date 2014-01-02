/*
 * Copyright (C) 2009 by Matthias Ringwald
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 * 3. Neither the name of the copyright holders nor the names of
 *    contributors may be used to endorse or promote products derived
 *    from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY MATTHIAS RINGWALD AND CONTRIBUTORS
 * ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL MATTHIAS
 * RINGWALD OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
 * BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS
 * OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED
 * AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
 * OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF
 * THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
 * SUCH DAMAGE.
 *
 */

/*
 *  Allows to inject mouse events into system event handler
 *  works with MouseSupport package
 */

#include "mouse_msgs.h"

#include <strings.h>

static CFMessagePortRef mouseMessagePort = NULL;

int mouseOpen(BOOL SHOWCursor)
{
    // If the port is already open, open it
	if (!mouseMessagePort)
		mouseMessagePort = CFMessagePortCreateRemote(NULL, CFSTR(MessagePortName));

    // Tell SpringBoard to enable the mouse pointer
    bool showcursor=false;
    if (SHOWCursor == YES)
	showcursor=true;

    if (mouseMessagePort && showcursor) {
        BOOL enabled = YES;
        NSData *data = [NSData dataWithBytes:(void *)&enabled length:sizeof(BOOL)];
        CFMessagePortSendRequest(mouseMessagePort, MouseMessageTypeSetEnabled, (CFDataRef)data, 1, 0, NULL, NULL);
    }

	return (mouseMessagePort == NULL) ? kCFMessagePortIsInvalid : kCFMessagePortSuccess;
}


void mouseCursorShow(BOOL enabled)
{
    if (mouseMessagePort) {
        NSData *data = [NSData dataWithBytes:(void *)&enabled length:sizeof(BOOL)];
        CFMessagePortSendRequest(mouseMessagePort, MouseMessageTypeSetEnabled, (CFDataRef)data, 1, 0, NULL, NULL);
    }
}

void mouseClose()
{
	if (mouseMessagePort) {
        // Tell SpringBoard to disable the mouse pointer
        BOOL enabled = NO;
        NSData *data = [NSData dataWithBytes:(void *)&enabled length:sizeof(BOOL)];
        CFMessagePortSendRequest(mouseMessagePort, MouseMessageTypeSetEnabled, (CFDataRef)data, 1, 0, NULL, NULL);

        // Close the mach port connection
        CFMessagePortInvalidate(mouseMessagePort);
        CFRelease(mouseMessagePort);
        mouseMessagePort = NULL;
    }
}

int mouseSendEvent(float x, float y, char buttons)
{
    int ret = kCFMessagePortIsInvalid;

    if (mouseMessagePort) {
        // Create and send message
        MouseEvent event;
        event.x = x;
        event.y = y;
        event.absolute = YES;
        event.buttons = buttons;

        NSData *data = [NSData dataWithBytes:(void *)&event length:sizeof(MouseEvent)];
        ret = CFMessagePortSendRequest(mouseMessagePort, MouseMessageTypeEvent, (CFDataRef)data, 1, 0, NULL, NULL);
    }

    return ret;
}


void TouchInPad(int N)
{

	if (N==0)
		N=11;

	int C=3;
	int R=0;
	while( (N-C) >0 )
		C+=3;
	R=(C / 3) - 1;
	C=N-C+2;
	int x = C * 106 + 54;
	int y = R * 54 + 292;

	NSLog(@"**********************************touch in x= %u y= %u",x,y);	


	mouseSendEvent(x,y, 0x01);
	mouseSendEvent(x,y, 0x00);

	//mouseSendEvent(54,54, 0x01);
	//mouseSendEvent(54,54, 0x00);




}
