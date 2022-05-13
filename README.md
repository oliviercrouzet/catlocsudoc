# Exemple de script de localisation dans le sudoc pour WinIBW.

Modifier selon le contexte.
Fermer l'application WinIBW et coller les 2 fonctions ci-dessous dans le fichier winibw.vbs (C:\oclcpica\WinIBW30\Profiles\prenom.nom\winibw.vbs).
Créer le fichier winibw.vbs s'il n'existe pas.


```
Sub Localiser
    dim ref
    dim tabref
    dim ppn
    dim biblionumber
    dim choix
    dim testbnf
    dim tagstr
    dim copynr
    dim sdate
    dim chemin
    dim oShell
    dim FSO
    dim monRapport
    dim niveau
    
    ' controle point de lancement
    niveau = application.activeWindow.variable("scr")
    if niveau <> "8A" and niveau <> "FI"  then
        msgbox "Vous ne pouvez pas lancer la localisation à ce niveau", vbExclamation, "Erreur point de départ"
        exit sub
    end if

    sdate = Date()
    'récupération des références dans le presse-papiers
    ref=application.activewindow.clipboard
    application.activewindow.clipboard = ""
    if mylike(ref,"\d{8}[\dX]#-#\d+") = false then
         msgbox "La chaine trouvée dans le presse-papiers ne semble pas correspondre à une référence de notice : " & vbLf & ref, vbExclamation, "Références non conformes"
         exit sub
    end if
    tabref = split(ref,"#-#")
    ppn = tabref(0)
    biblionumber = tabref(1)
    
    ' recherche de la notice        
    Application.activeWindow.command "che ppn " & ppn
    ' Send the "F7" command = mode modification
    application.activeWindow.simulateIBWKey "F7"
    
    ' instanciation d'un fichier d'écriture pour le rapport
    Set oShell = CreateObject("WScript.Shell")
    chemin = oShell.ExpandEnvironmentStrings("%USERPROFILE%") & "\rapportLOCALISATIONS.txt"
    Set oShell = nothing
    Set FSO = CreateObject("Scripting.FileSystemObject")
    Set monRapport = FSO.OpenTextFile( chemin, 8, true, 0 ) 
    
    ' controle statut notice
    if right(application.activeWindow.materialCode,1) = "B" then
        MsgBox "Ceci est une notice en statut B" & vbLf & "Transmettre aux catalogueurs !", vbExclamation, "Statut B"
        monRapport.Write ppn & vbTab & biblionumber & vbTab & "statut_B" & vbTab & sdate & VbCrLf
        monRapport.close
        Set FSO = nothing
        application.activeWindow.simulateIBWKey "FE"
        exit sub
    end if
    
    ' test BNF
    testbnf = application.activeWindow.title.findtag ("002",0,true,true)
    if mid(testbnf,7,5) = "FRBNF" then
        msgbox "NOTICE BNF à VERIFIER (localisation annulée) :" & vbLf & "=> Mettre de coté pour les catalogueurs"
        monRapport.Write ppn & vbTab & biblionumber & vbTab & "noticeBNF" & vbTab & sdate & VbCrLf
        monRapport.close
        Set FSO = nothing
        application.activeWindow.simulateIBWKey "FE"
        exit sub
    end if
    
    ' on vérifie que le document n'est pas déja localisé
    if application.activeWindow.title.find ("930 ##$b693872102") = true then
        msgbox "Ce document est déja localisé à Lyon3 (RCR 693872102)", VbExclamation,"Document déja localisé"
        application.activeWindow.simulateIBWKey "FE"     
        exit sub
    end if

    ' L035 : on vérifie qu'elle n'est pas déja entrée (par bourg)
    L035toReg = 1
    if application.activeWindow.title.findtag ("L035",0,true,false) = "" then
        application.activeWindow.title.endOfBuffer
        application.activeWindow.title.insertText "L035 ##$a" & biblionumber
    else 
        L035toReg = 0
    end if
    
    choix = msgbox ("Enregistrer ?",vbYesNo, "Confirmer ou annuler la localisation")
    if choix = 6 then
        ' mode expert pour pouvoir éviter d'avoir à saisir les données
        application.activeWindow.noviceMode = false
        ' enregistrer les données locales s'il y a lieu
        if ( L035toReg ) then 
            application.activeWindow.simulateIBWKey "FR"
        end if
        ' création de l'exemplaire
        tagstr = "e01"
      copynr = 1        
        application.activeWindow.command "cre " & tagstr, false     
      do while application.activeWindow.status = "ERROR" and copynr < 99        
            copynr = copynr + 1
        if copynr < 10 then
            tagstr = "e0" & copynr
        else
            tagstr = "e" & copynr
        end if
        application.activeWindow.command "cre " & tagstr, false
        loop 
      application.activeWindow.title.insertText tagstr & " $bx" & vbLf & "930 $b693872102$ju"
      application.activeWindow.simulateIBWKey "FR"
      monRapport.Write ppn & vbTab & biblionumber & vbTab & "localisation" & vbTab & sdate & VbCrLf
    else 'choix = 7 => exit sans enregistrer
        application.activeWindow.simulateIBWKey "FE"
    end if
    monRapport.close
    Set FSO = nothing
   
End sub

Function mylike(ByVal Name,ByVal pattern)
    Dim objRegExpr
    Set objRegExpr = New regexp
    objRegExpr.Pattern = pattern
    objRegExpr.Global = True

    Set colMatches = objRegExpr.Execute(Name)

    if colMatches.Count =0 Then
      mylike=false
    else
      mylike=true
    End If
End Function
```
