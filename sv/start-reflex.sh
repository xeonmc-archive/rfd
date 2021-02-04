[[ -n "$NAME" ]] && NAME="+sv_hostname $NAME "
[[ -n "$PORT" ]] && PORT="+sv_gameport $PORT "
[[ -n "$PUBLIC" ]] && PUBLIC="+sv_steam $PUBLIC "
[[ -n "$REPLAY" ]] && REPLAY="+sv_autorecord $REPLAY "
[[ -n "$PASSWORD" ]] && PASSWORD="+sv_password $PASSWORD "
[[ -n "$MAXPLAYERS" ]] && MAXPLAYERS="+sv_maxclients $MAXPLAYERS "
[[ -n "$REFPASSWORD" ]] && RCONPASSWORD="+rcon_password $REFPASSWORD "
[[ -n "$REFPASSWORD" ]] && REFPASSWORD="+sv_refpassword $REFPASSWORD "
FLAG="$NAME$PORT$PUBLIC$REPLAY$PASSWORD$MAXPLAYERS$REFPASSWORD$RCONPASSWORD$FLAG"
[[ -d "/reflex/config" ]] && cp /reflex/config/* /reflex/
exec wine reflexded.exe $FLAG
