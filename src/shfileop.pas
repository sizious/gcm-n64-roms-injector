{

  Unit SHFileOp
  SHFileOperation : Operations sur les fichiers par Windows
  Par Nono40 (adaptation en unit par SiZiOUS).
}

unit SHFileOp;

interface

Uses
  ShellAPI, Classes;

// D�finition de la fonctionen Pascal, c'est plus facile � utiliser que l'API
//
// D�finition d'un type ensemble pour les options de la fonctions
Type TSHFileOperationOptions = Set Of (oFOF_MULTIDESTFILES    ,
                                       oFOF_CONFIRMMOUSE      ,
                                       oFOF_SILENT            ,
                                       oFOF_RENAMEONCOLLISION ,
                                       oFOF_NOCONFIRMATION    ,
                                       oFOF_WANTMAPPINGHANDLE ,
                                       oFOF_ALLOWUNDO         ,
                                       oFOF_FILESONLY         ,
                                       oFOF_SIMPLEPROGRESS    ,
                                       oFOF_NOCONFIRMMKDIR    ,
                                       oFOF_NOERRORUI         );

//Constante pour l'op�ration de SHFileOperation.
//Pour copier, etc...
{const
  FO_MOVE   : Cardinal = 0;
  FO_COPY   : Cardinal = 1;
  FO_DELETE : Cardinal = 2;
  FO_RENAME : Cardinal = 3;

  Finalement, pas besoin de ces constantes :D
  Delphi le g�re tr�s bien ... ;)
  Temps mieux!
}

//Exportation des fonctions
function ShFileOperationPascal(Operation : Cardinal ; NomsFROM, NomsTO : TStrings ; Options : TSHFileOperationOptions ; Titre : string) : boolean;
function SHCopyFiles(Source, Destination : string ; Options : TSHFileOperationOptions ; Title : string) : boolean;
function SHDeleteFiles(Source : string ; Options : TSHFileOperationOptions ; Title : string) : boolean;

implementation

// Prototype de la fonction en Pascal
Function ShFileOperationPascal(Operation:Cardinal;NomsFROM,NomsTO:TStrings;Options:TSHFileOperationOptions;Titre:String):Boolean;
Var Info        :TSHFileOPStruct;
    ChaineFROM  :String;
    ChaineTO    :String;
    fl          :Word;

// Fonction interne de conversion d'un TStrings et Chaine � z�ro terminal multiple.
// Le r�sultat est retourn� en String plutot qu'en PChar pour plus de facilit� de manipulation
function ConcatTStrings(Liste : TStrings) : string;
var
  i : Integer;

Begin
  If (Liste=Nil) Or (Liste.Count = 0) Then Result:=#0#0
  Else Begin Result:='';
  For i:=0 To Liste.Count-1 Do Result:=Result+Liste[i]+#0;
  Result:=Result+#0;
  End;
End;

Begin
  // Transformation des TStrings en Chaine � z�ro terminal multiple.
  ChaineFROM:=ConcatTStrings(NomsFROM);
  ChaineTO  :=ConcatTStrings(NomsTO  );
  Titre     :=Titre+#0;

  // Pr�paration des options sous forme de 'flag' pour la fonction API
  fl:=0;
  If oFOF_MULTIDESTFILES    In Options Then Inc(fl,FOF_MULTIDESTFILES   );
  If oFOF_CONFIRMMOUSE      In Options Then Inc(fl,FOF_CONFIRMMOUSE     );
  If oFOF_SILENT            In Options Then Inc(fl,FOF_SILENT           );
  If oFOF_RENAMEONCOLLISION In Options Then Inc(fl,FOF_RENAMEONCOLLISION);
  If oFOF_NOCONFIRMATION    In Options Then Inc(fl,FOF_NOCONFIRMATION   );
  If oFOF_WANTMAPPINGHANDLE In Options Then Inc(fl,FOF_WANTMAPPINGHANDLE);
  If oFOF_ALLOWUNDO         In Options Then Inc(fl,FOF_ALLOWUNDO        );
  If oFOF_FILESONLY         In Options Then Inc(fl,FOF_FILESONLY        );
  If oFOF_SIMPLEPROGRESS    In Options Then Inc(fl,FOF_SIMPLEPROGRESS   );
  If oFOF_NOCONFIRMMKDIR    In Options Then Inc(fl,FOF_NOCONFIRMMKDIR   );
  If oFOF_NOERRORUI         In Options Then Inc(fl,FOF_NOERRORUI        );

  // Pr�paration de la structure TSHFileOPStruct qui contient tous les param�tres de la fonction
  // Il n'est pas utile de donner une fen�tre parent pour la progresion si elle est affich�e. Dans ce
  // cas l'affichage de la progression n'est pas li�e � votre application.
  // Vous remarquerez que ChaineFROM et ChaineTO ne sont pas converties en PChar, mais
  // on donne seulement l'adresse du premier caract�re. Ceci est possible car les #0 ont �t� ajout�s
  // dans les chaines au pr�alable.
  // Le titre de la fen�tre n'est utilis� que si la progression est active et en mode simple,
  // c'est � dire sans l'option oFOF_SILENT et avec l'option oFOF_SIMPLEPROGRESS
  With Info Do
  Begin
    Wnd                   :=0;                            // Handle de la fen�tre parent de la progression
    wFunc                 :=Operation;                    // Type d'op�ration
    pFrom                 :=@ChaineFROM[1];               // Noms de fichiers en entr�e
    pTo                   :=@ChaineTO  [1];               // Noms de fichiers en sortie
    fFlags                :=fl;                           // Options
    fAnyOperationsAborted :=False;                        // Code de retour
    hNameMappings         :=Nil;                          // J'sais pas encore � quoi �a sert...
    lpszProgressTitle     :=@Titre[1];                    // Tire de la fen�tre de progression
  End;
  Result := Not Boolean(ShFileOperation(Info)) And Not Info.fAnyOperationsAborted;
end;

//Fonction bonus de [big_fury]SiZiOUS ;)
//Fonction qui copie des fichiers grace au Shell
function SHCopyFiles(Source, Destination : string ; Options : TSHFileOperationOptions ; Title : string) : boolean;
var
  AStringFrom, AStringTo : TStringList;

begin
  AStringFrom := TStringList.Create();
  AStringTo := TStringList.Create();
  try
    AStringFrom.Add(Source);
    AStringTo.Add(Destination);
    Result := ShFileOperationPascal(FO_COPY, AStringFrom, AStringTo, Options, Title);
  finally;
    AStringFrom.Free;
    AStringTo.Free;
  end;
end;

//Fonction bonus de [big_fury]SiZiOUS ;)
//Fonction qui efface des fichiers grace au Shell
function SHDeleteFiles(Source : string ; Options : TSHFileOperationOptions ; Title : string) : boolean;
var
  AStringFrom : TStringList;

begin
  AStringFrom := TStringList.Create();
  try
    AStringFrom.Add(Source);
    Result := ShFileOperationPascal(FO_DELETE, AStringFrom, nil, Options, Title);
  finally;
    AStringFrom.Free;
  end;
end;

end.