/*
  Part of the GUI for Processing library 
  	http://www.lagers.org.uk/g4p/index.html
	http://gui4processing.googlecode.com/svn/trunk/
	
  Copyright (c) 2008-09 Peter Lager

  This library is free software; you can redistribute it and/or
  modify it under the terms of the GNU Lesser General Public
  License as published by the Free Software Foundation; either
  version 2.1 of the License, or (at your option) any later version.

  This library is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
  Lesser General Public License for more details.

  You should have received a copy of the GNU Lesser General
  Public License along with this library; if not, write to the
  Free Software Foundation, Inc., 59 Temple Place, Suite 330,
  Boston, MA  02111-1307  USA
 */

package guicomponents;

import java.awt.event.ActionEvent;
import java.awt.event.ActionListener;
import java.lang.reflect.Method;

import javax.swing.Timer;

import processing.core.PApplet;

/**
 * This class is used to trigger events at user defined intervals. The event will
 * call a user defined method/function. The only restriction is that the method
 * used has no parameters and returns void eg 
 * <pre>
 * void fireBall(){ ... }
 * </pre>
 * 
 * It has no visible GUI representation so will not appear in the GUI.
 * 
 * @author Peter Lager
 *
 */
public class GTimer {

	/** This must be set by the constructor */
	protected PApplet app;

	/** The object to handle the event */
	protected Object eventHandlerObject = null;
	/** The method in eventHandlerObject to execute */
	protected Method eventHandler = null;

	// The number of repeats i.e. events to be fired.
	protected int nrepeats = -1;
	
	protected Timer timer = null;

	/**
	 * Create the GTimer object with this ctor.
	 * 
	 * 'methodName' is the method/function to be called every 'interval' 
	 * milliseconds. 'obj' is the object that contains the method/function
	 * 'methodName'
	 * 
	 * For most users 'methodName' will be in their main sketch so this
	 * parameter has the same value as 'theApplet'
	 * 
	 * @param theApplet a reference to the PApplet object (invariably <b>this</b>)
	 * @param obj the object that has the method to be executed (likely to be <b>this</b>)
	 * @param methodName the name of the method to be called by the timer
	 * @param interval the time (in millisecs) between function calls
	 */
	public GTimer(PApplet theApplet, Object obj, String methodName, int interval){
		app = theApplet;
		createEventHandler(obj, methodName);
		// If we have something to handle the event then create the Timer
		if(eventHandlerObject != null){
			timer = new Timer(interval, new ActionListener(){

				public void actionPerformed(ActionEvent e) {
					fireEvent();
				}

			});
			
			timer.stop();
		}
		
	}

	/**
	 * See if 'obj' has a parameterless method called 'methodName' and
	 * if so keep a reference to it.
	 * 
	 * @param obj
	 * @param methodName
	 */
	protected void createEventHandler(Object obj, String methodName){
		try{
			this.eventHandler = obj.getClass().getMethod(methodName, new Class[0] );
			eventHandlerObject = obj;
		} catch (Exception e) {
			eventHandlerObject = null;
			System.out.println("The class " + obj.getClass().getSimpleName() + " does not have a method called " + methodName);
		}
	}

	/**
	 * Attempt to fire an event for this timer. This will call the 
	 * method/function defined in the ctor.
	 */
	protected void fireEvent(){
		if(eventHandler != null){
			try {
				eventHandler.invoke(eventHandlerObject, (Object[]) null);
				if(--nrepeats == 0)
					stop();
			} catch (Exception e) {
				System.out.println("Disabling " + eventHandler.getName() + " due to an unknown error");
				eventHandler = null;
				eventHandlerObject = null;
			}
		}
	}

	/**
	 * Start the timer (call the method forever)
	 */
	public void start(){
		this.nrepeats = -1;
		if(timer != null)
			timer.start();
	}
	
	/**
	 * Start the timer and call the method for the number of
	 * times indicated by nrepeats
	 * If nrepeats is <=0 then repeat forever
	 * 
	 * @param nrepeats
	 */
	public void start(int nrepeats){
		this.nrepeats = nrepeats;
		if(timer != null)
			timer.start();
	}

	/**
	 * Stop the timer (can be restarted with start() method)
	 */
	public void stop(){
		if(timer != null)
			timer.stop();
	}

	/**
	 * Is the timer running?
	 * @return true if running
	 */
	public boolean isRunning(){
		if(timer != null)
			return timer.isRunning();
		else
			return false;
	}
	
	/**
	 * Set the interval between events
	 * @param msecs interval in milliseconds
	 */
	public void setInterval(int msecs){
		if(timer != null)
			timer.setDelay(msecs);
	}
	
	/**
	 * Get the interval time (milliseconds)between 
	 * events.
	 * @return interval in millsecs or -1 if the timer failed to
	 * be created.
	 * 
	 */
	public int getInterval(){
		if(timer != null)
			return timer.getDelay();
		else
			return -1;		
	}
	
	/**
	 * See if the GTimer object has been created successfully
	 * @return true if successful
	 */
	public boolean isValid(){
		return (eventHandlerObject != null && timer != null);
	}

}
