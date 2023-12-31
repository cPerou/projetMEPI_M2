### Modele dont la sensibilite doit etre analysee dans le cadre du projet MODE-MPI 2023-2024

### Le modele est ici defini sous forme de fonction pour faciliter vos analyses de sensibilite (AS)
### La fonction renvoie les sorties ponctuelles qui sont a analyser dans l'AS


# Modification du modele --------------------------------------------------


modApplimodif <- function(parametre){  
  
  # CONDITIONS DE SIMULATION
  temps = 2*365; # nb de pas de temps (ou simulations), en jours
  # initialisation pour la sauvegarde de 4 sorties ponctuelles pour chaque jeu de parametres
  sorties <- matrix(0, nrow=nrow(parametre), ncol=4)
  
  
  
  # boucle des scenarios de l'echantillonnage de l'AS
  for (i in 1:nrow(parametre)) { 
    
    
    # STRUCTURE & PARAMETRES DU MODELE
    
    # Parametres demographiques
    K = parametre[i,1];		# nombre maximal d'individus que le milieu peut supporter
    sr = parametre[i,2];	# sex-ratio
    m1 = parametre[i,3];	# mortalité naturelle des nouveaux-nés
    m2 = parametre[i,4];	# mortalité naturelle des jeunes
    m3 = parametre[i,5];	# mortalité naturelle des adultes
    f2 = parametre[i,6];	# taux de fécondité des jeunes
    f3 = parametre[i,7];	# taux de fécondité des adultes
    portee = parametre[i,8];	# effectif maximal d'une portée
    t1 = parametre[i,9];	# probabilité de passage de la classe d'âge "nouveau-né" à "jeune"
    t2 = parametre[i,10];	# probabilité de passage de la classe d'âge "jeune" à "adulte"
    
    # Parametres lies a l'AP
    trans_inter = parametre[i,11]; # force d'infection INTER-CLASSE
    trans_intra=parametre[i,12] # force d'infection INTRA-CLASSE
    lat = parametre[i,13];	# taux de la latence
    rec = parametre[i,14];	# taux de passage à un état d'immmunité
    loss = parametre[i,15];	# taux de passage d'un état d'immunité à un état sensible (sain)
    madd = parametre[i,16];	# mortalité lié à l'infection par l'AP
    
    # INITIALISATION
    MAT <- array(0, dim=c(4,4,temps)); # nb indiv par classe d'age en ligne (derniere ligne = pop tot), 
    #etat de sante en colonne, pas de temps (dimension 3)
    eff<- matrix(0,16,temps) ;#objet de stockage des effectifs 
    nvinf <- array(0, dim=c(temps));
    # conditions initiales (la population est a sa structure d'equilibre, calculee par ailleurs)
    #MAT[classe_age, etat_sante, jour]
    MAT[1,1,1] <- 27; # Effectif des individus nouveaux-nes sains le premier jour
    MAT[2,1,1] <- 23; # Effectif des individus jeunes sains le premier jour
    MAT[3,1,1] <- 36; # Effectif des individus adultes sains le premier jour 
    #Tous les individus sains
    
    MAT[3,3,1] <- 1;  # Effectif des individus adultes infectes infectieux le premier jour
    
    # effectifs par etat de sante
    MAT[4,1,1] <- sum(MAT[1:3,1,1]);#Effectif total des individus de toutes les classes d'age sains le premier jour
    MAT[4,2,1] <- sum(MAT[1:3,2,1]);#Pour le deuxieme etat de sante 
    MAT[4,3,1] <- sum(MAT[1:3,3,1]);#Pour le troisieme etat de sante 
    MAT[4,4,1] <- sum(MAT[1:3,4,1]);#Pour le quatrieme etat de sante 
    
    #Objet eff a remplir pour avoir les etats initiaux
    eff[1,1]<-MAT[1,1,1]
    eff[5,1]<-MAT[2,1,1]
    eff[9,1]<-MAT[3,1,1]
    eff[11,1]<-MAT[3,3,1]
    
    # SIMULATIONS
    # boucle du temps
    for (t in 1:(temps-1)) { 
      # Les nouveaux-nes
      # RQ : les naissances sont XX, les nouveaux nes etant dans l'etat XX
      N <- sum(MAT[4,,t]);	# taille de la pop en t
      MAT[1,1,t+1] <- MAT[1,1,t]*(1-m1-t1-trans_inter*MAT[2,3,t]*MAT[3,3,t]- trans_intra*MAT[1,3,t]/N )+ loss*MAT[1,4,t] 
      + max(0, sr*portee*(sum(MAT[2,,t])*f2 + sum(MAT[3,,t])*f3) * (1 - N/K)); 
      MAT[1,2,t+1] <- MAT[1,2,t]*(1-m1-t1-lat) + MAT[1,1,t]*(trans_inter*MAT[2,3,t]*MAT[3,3,t]+trans_intra*MAT[1,3,t])/N; 
      MAT[1,3,t+1] <- MAT[1,3,t]*(1-m1-madd-t1-rec) + lat*MAT[1,2,t]; 
      MAT[1,4,t+1] <- MAT[1,4,t]*(1-m1-t1-loss) + rec*MAT[1,3,t]; 
      # Les jeunes
      MAT[2,1,t+1] <- MAT[1,1,t]*t1	+ MAT[2,1,t]*(1-m2-t2-trans_inter*MAT[1,3,t]*MAT[3,3,t]- trans_intra*MAT[2,3,t]/N) + loss*MAT[2,4,t];
      MAT[2,2,t+1] <- MAT[1,2,t]*t1	+ MAT[2,2,t]*(1-m2-t2-lat) + MAT[2,1,t]*(trans_inter*MAT[1,3,t]*MAT[3,3,t] + trans_intra*MAT[2,3,t])/N;
      MAT[2,3,t+1] <- MAT[1,3,t]*t1	+ MAT[2,3,t]*(1-m2-madd-t2-rec)	+ lat*MAT[2,2,t];
      MAT[2,4,t+1] <- MAT[1,4,t]*t1	+ MAT[2,4,t]*(1-m2-t2-loss)	+ rec*MAT[2,3,t];
      # Les adultes
      MAT[3,1,t+1] <- MAT[2,1,t]*t2	+ MAT[3,1,t]*(1-m3-trans_inter*MAT[1,3,t]*MAT[2,3,t]- trans_intra*MAT[3,3,t]/N) + loss*MAT[3,4,t];
      MAT[3,2,t+1] <- MAT[2,2,t]*t2	+ MAT[3,2,t]*(1-m3-lat)	+ MAT[3,1,t]*(trans_inter*MAT[1,3,t]*MAT[2,3,t] + trans_intra*MAT[3,3,t])/N;
      MAT[3,3,t+1] <- MAT[2,3,t]*t2	+ MAT[3,3,t]*(1-m3-madd-rec) + lat*MAT[3,2,t];
      MAT[3,4,t+1] <- MAT[2,4,t]*t2	+ MAT[3,4,t]*(1-m3-loss) + rec*MAT[3,3,t];
      # calcul des effectifs  N par etat de sante
      MAT[4,1,t+1] <- sum(MAT[1:3,1,t+1]); 
      MAT[4,2,t+1] <- sum(MAT[1:3,2,t+1]); 
      MAT[4,3,t+1] <- sum(MAT[1:3,3,t+1]); 
      MAT[4,4,t+1] <- sum(MAT[1:3,4,t+1]);
      nvinf[t+1]   <- trans*MAT[4,1,t]*MAT[4,3,t]/N
      
      #stockage des donnees effectif dans un objet eff
      #Nouveaux-nes
      eff[1,t+1]<-MAT[1,1,t+1];
      eff[2,t+1]<-MAT[1,2,t+1];
      eff[3,t+1]<-MAT[1,3,t+1];
      eff[4,t+1]<-MAT[1,4,t+1];
      #Jeunes
      eff[5,t+1]<-MAT[2,1,t+1];
      eff[6,t+1]<-MAT[2,2,t+1];
      eff[7,t+1]<-MAT[2,3,t+1];
      eff[8,t+1]<-MAT[2,4,t+1];
      #Adultes
      eff[9,t+1]<-MAT[3,1,t+1];
      eff[10,t+1]<-MAT[3,2,t+1];
      eff[11,t+1]<-MAT[3,3,t+1];
      eff[12,t+1]<-MAT[3,4,t+1];
      
      #Total
      eff[13,t+1]<-MAT[4,1,t+1];
      eff[14,t+1]<-MAT[4,2,t+1];
      eff[15,t+1]<-MAT[4,3,t+1];
      eff[16,t+1]<-MAT[4,4,t+1];
      
      
      
    }# fin boucle temps
    
    # sorties ponctuelles a analyser
    # Taux des infectes au dernier jour
    sortie1 <- (MAT[4,2,temps]+MAT[4,3,temps])/sum(MAT[4,,temps])
    # Incidence le dernier jour
    sortie2 <- nvinf[temps]
    # Maximum d'infectes infectieux au cours du temps
    sortie3 <- max(MAT[4,3,1:temps])
    # Incidence (total de nouveaux infectes par an)
    sortie4 <- sum(nvinf[1:365])
    
    sorties[i,1] <- sortie1;
    sorties[i,2] <- sortie2;
    sorties[i,3] <- sortie3;
    sorties[i,4] <- sortie4;
    
    
  }# fin boucle scenarios AS
  #return(sorties)
  return(eff)
} # fin fonction du modele

# END

# Simulations du modele ---------------------------------------------------


#Valeur des parametres : 
ValNominale <- c(100,0.5,0.0014,0.00029,0.0019,0.0019,0.0082,5,1/365,1/365,0.3, #10 parametres
                 1/5,1/4,1/20,1/100,0.001)# 5 parametres maladie
# Trans_inter = 1/5
# Trans_intra = 1/4

PAR<-matrix(ValNominale, nrow=1)
PAR


# Tests -------------------------------------------------------------------

# Simulation 1
sim1<-modAppli(parametre = PAR)
# length(sim1) # 11680
sim1<-t(sim1)
colnames(sim1)<- 1:16 