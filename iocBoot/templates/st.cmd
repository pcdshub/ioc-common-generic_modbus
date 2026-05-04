#!$$IOCTOP/bin/$$IF(ARCH,$$ARCH,linux-x86_64)/gmb

< envPaths
epicsEnvSet( "ENGINEER" , "$$ENGINEER" )
epicsEnvSet( "IOCSH_PS1", "$$IOCNAME>" )
epicsEnvSet( "IOC_PV",    "$$IOC_PV"   )
epicsEnvSet( "LOCATION",  "$$IF(LOCATION,$$LOCATION,$$IOC_PV)")
epicsEnvSet( "IOCTOP",    "$$IOCTOP"   )
epicsEnvSet( "TOP",       "$$TOP"      )
epicsEnvSet( "MB_TCP",    "0"          )
epicsEnvSet( "MB_RTU",    "1"          )
epicsEnvSet( "MB_ASCII",  "2"          )

cd( "$(IOCTOP)" )

# Run common startup commands for linux soft IOC's
< /reg/d/iocCommon/All/pre_linux.cmd

# Register all support components
dbLoadDatabase("dbd/gmb.dbd")
gmb_registerRecordDeviceDriver(pdbbase)

# Bump up queue sizes!
scanOnceSetQueueSize(4000)
callbackSetQueueSize(4000)

# Configure each device

$$LOOP(GMB)
drvAsynIPPortConfigure( "GMB$$INDEX", "$$HOST:$$IF(PORT,$$PORT,502) TCP", 0, 0, 1 )
modbusInterposeConfig("GMB$$INDEX",$(MB_$$IF(TYPE,$$TYPE,TCP)),$$IF(RTO,$$RTO,5000),$$IF(WTO,$$WTO,0))
$$IF(DEBUG,,#)asynSetTraceIOMask("GMB$$INDEX", 0, 4)
$$IF(DEBUG,,#)asynSetTraceMask("GMB$$INDEX", 0, 9) 
$$IF(LOG,,#)asynSetTraceFile("GMB$$INDEX", 0, "/reg/d/iocData/$(IOC)/logs/GMB$$INDEX.log" )
$$ENDLOOP(GMB)

# drvModbusAsynConfigure(modbusPort, asynPort, slave, func, offset, length, type, polltime, debugname)

$$LOOP(REGION)
$$LOOP(GMB)
drvModbusAsynConfigure("GMB$$(INDEX)_$$NAME", "GMB$$INDEX", $$IF(SLAVE,$$SLAVE,0), $$FUNC, $$ADDR, $$LEN, $$IF(TYPE,$$TYPE,0), $$IF(POLL,$$POLL,5000), "GMB$$(INDEX)_$$NAME")
$$ENDLOOP(GMB)
$$ENDLOOP(REGION)

# Load record instances

dbLoadRecords( "db/iocSoft.db",            "IOC=$(IOC_PV)" )
dbLoadRecords( "db/save_restoreStatus.db", "P=$(IOC_PV):" )
$$LOOP(GMB)
dbLoadRecords( "db/gmb.db",       "DEV=$$BASE,N=$$(INDEX)" )
dbLoadRecords( "db/asynRecord.db", "P=$$BASE:,R=asyn,PORT=GMB$$INDEX,ADDR=0,OMAX=80,IMAX=80")
$$ENDLOOP(GMB)

# Setup autosave
set_savefile_path( "$(IOC_DATA)/$(IOC)/autosave")
set_requestfile_path( "$(TOP)/autosave")
save_restoreSet_status_prefix( "$(IOC_PV):" )
save_restoreSet_IncompleteSetsOk( 1 )
save_restoreSet_DatedBackupFiles( 1 )

# Just restore the settings
set_pass0_restoreFile( "$(IOC).sav" )
set_pass1_restoreFile( "$(IOC).sav" )

# Initialize the IOC and start processing records
iocInit()

# Start autosave backups
create_monitor_set( "$(IOC).req", 5, "" )

# All IOCs should dump some common info after initial startup.
< /reg/d/iocCommon/All/post_linux.cmd
