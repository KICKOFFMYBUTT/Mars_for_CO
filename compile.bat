@echo off

rem Compile Modified Java Classes

:: javac mars\Settings.java
:: javac mars\mips\hardware\Register.java
:: javac mars\mips\hardware\Memory.java
:: javac mars\mips\instructions\InstructionSet.java

rem Make JAR Archieve

jar cvfm Mars_m.jar META-INF\MANIFEST.MF .
