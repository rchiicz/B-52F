# $Id$
#
# Nasal script to print errors to the screen when aircraft exceed design limits:
#  - extending flaps above maximum flap extension speed(s)
#  - extending gear above maximum gear extension speed
#  - exceeding Vna
#  - exceeding structural G limits
#
# To use, include this .nas file and define one or more of
# limits/max-flap-extension-speed/speed
# limits/max-flap-extension-speed/flaps
# limits/vne
# limits/max-gear-extension-speed
# limits/max-positive-g
# limits/max-negative-g (must be defined in max-positive-g defined)
#
# You can define multiple max-flap-extension-speed entries for max extension
# speeds for different flap settings.

var checkFlaps = func(n) {
  var flapsetting = n.getValue();
  if (flapsetting == 0)
    return;

  var airspeed = getprop("velocities/airspeed-kt");
  var ltext = "";

  var limits = props.globals.getNode("limits");

  if ((limits != nil) and (limits.getChildren("max-flap-extension-speed") != nil))
  {
    var children = limits.getChildren("max-flap-extension-speed");
    foreach(var c; children)
    {
      if ((c.getChild("flaps") != nil) and
          (c.getChild("speed") != nil)     )
      {
        var flaps = c.getChild("flaps").getValue();
        var speed = c.getChild("speed").getValue();

        if ((flaps != nil)        and
            (speed != nil)        and
            (flapsetting > flaps) and
            (airspeed > speed)       )
        {
          ltext = "Flaps extended above maximum flap extension speed!";
        }
      }
    }

    if (ltext != "")
    {
      screen.log.write(ltext);
    }
  }
}


var checkGear = func(n) {
  if (!n.getValue())
    return;

  var airspeed = getprop("velocities/airspeed-kt");
  var max_gear = getprop("limits/max-gear-extension-speed");

  if ((max_gear != nil) and (airspeed > max_gear))
  {
    screen.log.write("Gear extended above maximum extension speed!");
  }
}


# Set the listeners
setlistener("controls/flight/flaps", checkFlaps);
setlistener("controls/gear/gear-down", checkGear);


var checkGandVNE = func {
  if (getprop("/sim/freeze/replay-state"))
    return;

  var g = getprop("/accelerations/pilot-gdamped") or 1;
  var max_positive = getprop("limits/max-positive-g");
  var max_negative = getprop("limits/max-negative-g");
  var msg = "";

  if ((max_positive != nil) and (g > max_positive))
  {
    msg = "Airframe structural positive-g load limit exceeded!";
  }

  if ((max_negative != nil) and (g < max_negative))
  {
    msg = "Airframe structural negative-g load limit exceeded!";
  }

  # Now check Vmo and Mmo
  var airspeed = getprop("velocities/airspeed-kt");
  var vmo      = getprop("limits/vmo");
  var mach     = getprop("velocities/mach");
  var mmo      = getprop("limits/mmo");

  if ((airspeed != nil) and (vmo != nil) and (airspeed > vmo))
  {
    msg = "Airspeed exceeds Vmo! ("~vmo~" kias)";
  }

  if ((mach != nil) and (mmo != nil) and (mach > mmo))
  {
    msg = "Airspeed exceeds Mmo! (mach "~mmo~")";
  }

  if (msg != "")
  {
    # If we have a message, display it, but don't bother checking for
    # any other errors for 10 seconds. Otherwise we're likely to get
    # repeated messages.
    screen.log.write(msg);
    settimer(checkGandVNE, 10);
  }
  else
  {
    settimer(checkGandVNE, 1);
  }
}

checkGandVNE();
