// ----------------------------------------------------------------------------  
// Name: button_trap
// Purpose: Show the right way to debounce a button press...
// adapted by fliphunter to handle very noisy switches with a programmable sample period.
// only produces press and release callbacks for paired debounced events as long the default condition is set properly.
// another thing to keep in mind with sensing switches is that due to the low current the switch contacts should be gold plated
// and rated for relatively low current. Switches rated for high current use may not have a good low current resistance
// until more substantial current is applied since there may be some oxidation on the contacts.
// ---------------------------------------------------------------------------- 
 
class button_trap
{
  static NORMALLY_HIGH = 1;
  static NORMALLY_LOW  = 0;
  static TRIP_CYCLES   = 3; // 50 milliseconds per count works with very noisy switches...
  static milli_delay   = 0.05
  
  _butt_run        = true;
  _butt_cnt        = 0;
  _butt_1_raw_cnt  = 0;
  _butt_0_raw_cnt  = 0;
  _butt_state      = -1;
  _butt_last       = -2;
  _butt_hit        = false;
  _pinread         = 0;
  _sample_rate     = 3;
  _pin             = null;
  _pull            = null;
  _polarity        = null;
  _pressCallback   = null;
  _releaseCallback = null;

  constructor(pin, pull, polarity, pressCallback, releaseCallback, sample_rate)
  {
    _pin             = pin;               //Unconfigured IO pin, eg hardware.pin2
    _pull            = pull;              //DIGITAL_IN_PULLDOWN, DIGITAL_IN or DIGITAL_IN_PULLUP
    _polarity        = polarity;          //Normal button state, ie 1 if button is pulled up and the button shorts to GND
    _sample_rate     = sample_rate;       // increase to require a longer hold time for input to be recognized.
    _pressCallback   = pressCallback;     //Function to call on a button press (may be null)
    _releaseCallback = releaseCallback;   //Function to call on a button release (may be null)
    
    _pin.configure(_pull, buttChanged.bindenv(this));
  }

  function debounce_till_settled(starting = false)
  {
    if (starting)
    {
      _butt_run = false;
    }
    
    _pinread = _pin.read();
    if (_pinread != _butt_last)
    {
      _butt_cnt = 0;
    }
    else
    {
      _butt_cnt++;
    }

    _butt_last = _pinread;

    if (_butt_cnt == _sample_rate)
    {
      _butt_state = _butt_last;
      if (_butt_state == 0)
      {
        _butt_0_raw_cnt++;
        if (_polarity == NORMALLY_HIGH)
          _butt_hit = true;
      }
      else
      {
        _butt_1_raw_cnt++;
        if (_polarity == NORMALLY_LOW)
          _butt_hit = true;
      }

      // call notifiers
      if ( _polarity == _butt_state )
      {
        // this considered the default state so will only report if the opposite state has been seen.
        // indicating a fully debounced transition took place.
        if ((_releaseCallback != null) && _butt_hit)
        {
          _releaseCallback();
        }
        _butt_hit = false;
      }
      else
      {
        if (_pressCallback != null)
        {
          _pressCallback();
        }
      }
     
      _butt_run = true;
    }
    else
    {
      _butt_run = false;
      imp.wakeup(milli_delay, debounce_till_settled.bindenv(this));
    }
  }    
  
  function buttChanged() {
    _butt_cnt = 0;
    
    if (_butt_run)
    {
      debounce_till_settled(true);
    }
  } 
  
  function bstatus() {
    return _butt_state;
  } 
} // end of button_trap class

//Example Instantiation
// use callbacks to catch short presses and or test bstatus for other tests...
b2 <- button_trap(hardware.pin2, DIGITAL_IN_PULLUP, button_trap.NORMALLY_HIGH,
            function(){server.log("Button 2 Pressed callback " + b2._butt_0_raw_cnt)},
            function(){server.log("Button 2 Released callback " + b2._butt_1_raw_cnt)},
            button_trap.TRIP_CYCLES
            );
         
// prime the logic.
b2.buttChanged();

/*  
 * example callback function tied to other routines and global variables...
 *
 
function upChanged(starting = false) {
  b2_signal = b2.bstatus();
  if (! starting )
    check_Sensors();
}

*/
         
// use this style of test if better for the logic of the program in a loop perhaps. 
// bstatus only changes value when the debounce conditions have been met.        
/*
if (b2.bstatus == 0)
{
  // button pressed and held
}

if (b2.bstatus == 1)
{
  // not pressed
}
*/
