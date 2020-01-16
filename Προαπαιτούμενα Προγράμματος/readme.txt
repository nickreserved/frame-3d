Για να φτάσει το Octave να εκτελέσει το πρόγραμμα, απαιτούνται πολλά πράγματα!

- Εγκατάσταση έκδοσης του Octave 64 bit.

- Εγκατάσταση έκδοσης του Java Development Kit (JDK) 64 bit. Εδώ θεωρούμε την έκδοση 11.0.5.

- Στο αρχείο octave.vbs στο φάκελο εγκατάστασης του Octave, αμέσως μετά τη γραμμή:
		Set wshShell = CreateObject( "WScript.Shell" )
	τοποθετούμε τη γραμμή
		wshShell.Environment("SYSTEM")("JAVA_HOME") = "c:\program files\java\jdk-11.0.5"

- Ενσωματώνουμε στο μητρώο των Windows το αρχείο java_fix_windows?.reg με τα παρακάτω περιεχόμενα:
	Windows Registry Editor Version 5.00
	[HKEY_LOCAL_MACHINE\SOFTWARE\JavaSoft\Java Runtime Environment]
	"CurrentVersion"="11.0.5"
	[HKEY_LOCAL_MACHINE\SOFTWARE\JavaSoft\Java Runtime Environment\11.0.5]
	"JavaHome"="C:\\Program Files\\Java\\jdk-11.0.5"
	"RuntimeLib"="C:\\Program Files\\Java\\jdk-11.0.5\\bin\\client\\jvm.dll"        ***
*** Όπου "client", βάζουμε "server" αν έχουμε Windows 10.

- Κατεβάζουμε στο φάκελο του προγράμματος τα αρχεια
	xercesImpl-2.12.0-sp1.jar
	xml-apis-ext-1.3.04.jar
τα οποία θα τα ξαναβρούμε μέσα στον κώδικα ως
	javaaddpath("xercesImpl-2.12.0-sp1.jar");
	javaaddpath("xml-apis-ext-1.3.04.jar");


- Εκτελούμε στο Octave την εντολή
	pkg install -forge io
και μέσα στον κώδικα θα ξαναβρούμε το
	pkg load io;
	
- Εκτελούμε το πρόγραμμα