snap install android-studio --classic

install:
1. burpsuite
2. gnirehtet
3. wireshark

adding ca to the device's system CA's

before installing the CA we need to convert it to PEM format and rename it using the following:

# convert your certificate to PEM format, for example from DER format
openssl x509 -in <DER CERT> -out <PEM CERT>

# obtain the hash of your certificate
openssl x509 -inform PEM -subject_hash_old -in <PEM CERT> | head -1

# copy the certificate to a new file with the "hash_name.0"
cp <PEM CERT> <HASH VALUE>.0


now we need to install the CA certificate, here are some ways of adding it:

1. bind method:

```bash
cp -r /system/etc/security/cacerts /data/local/tmp/cacerts
mount -o bind /data/local/tmp/cacerts /system/etc/security/cacerts

adb push <CERT> /data/local/tmp/cacerts/
adb shell chmod 664 /data/local/tmp/cacerts/<CERT>
```

2. remounting - requires adbd to run as root (special root)

```bash
adb root
adb remount 
adb push <CERT> /system/etc/security/cacerts/
adb shell chmod 644 /system/etc/security/cacerts/<CERT>
adb reboot
```


3. android 14 - special change to location of root CAs
    a. creating the cacerts directory

```bash
        mount -t tmpfs tmpfs /system/etc/security/cacerts
        cp /apex/com.android.conscrypt/cacerts/* /system/etc/security/cacerts/

        cp <burp certificates> /system/etc/security/cacerts/

        chown root:root /system/etc/security/cacerts/

        chown root:root /system/etc/security/cacerts/*
        chmod 644 /system/etc/security/cacerts/*

        chcon u:subject_r:system_file:s0 /system/etc/security/cacerts/*
```

    b. updating all processes namespaces

```bash
    nsenter --mount=/proc/<PID>/ns/mnt -- /bin/mount --bind /system/etc/security/cacerts /apex/com.android.conscrypt/cacerts

    # PID is the pid of the zygote64 process
```

imo 2024.05.1091

zello