extends Node

var X = 360
var Y = 640

func getMirrored(v):
    var mirrored_x = X + (X - v.x)
    var mirrored_y = Y + (Y - v.y)
    return Vector2(mirrored_x, mirrored_y)
