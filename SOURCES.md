# Sources et Provenance des Données

## Jeu de données principal
- **Organisme / Pathogène :** *Salmonella enterica* (Salmonellose)
- **Source :** NCBI Pathogen Detection (National Center for Biotechnology Information)
- **Projet :** Isolats mondiaux séquencés par WGS (Whole Genome Sequencing)
- **Identifiant du cluster / jeu :** `PDG000000002` (Salmonella enterica)
- **Nom du fichier :** `PDG000000002.1697.amr.metadata.tsv` (au sein de `latest_kmer/Metadata/`)
- **URL de téléchargement direct :**
  `https://ftp.ncbi.nlm.nih.gov/pathogen/Results/Salmonella/latest_kmer/Metadata/PDG000000002.1697.amr.metadata.tsv`
- **Répertoire parent :**
  `https://ftp.ncbi.nlm.nih.gov/pathogen/Results/Salmonella/latest_kmer/Metadata/`
- **Format :** TSV (Tab-Separated Values)
- **Taille estimée :** ~123 Mo
- **Date d'accès / téléchargement :** 06 novembre 2026

## Colonnes d'intérêt exploitées dans le projet
1. `target_acc` / `#label` : Identifiant unique de l'isolat / de l'assemblage.
2. `scientific_name` : Nom taxonomique (*Salmonella enterica*).
3. `serovar` : Sérotype identifié (ex: Enteritidis, Typhimurium, etc.).
4. `epi_type` : Catégorie épidémiologique (`clinical` vs `environmental/food/other`).
5. `isolation_source` : Source biologique d'isolement (sang, selles, volaille, eau, etc.).
6. `geo_loc_name` : Localisation géographique de prélèvement.
7. `collection_date` : Année / date de collecte de l'échantillon.
8. `AMR_genotypes` : Liste exhaustive des gènes de résistance détectés par AMRFinderPlus.
9. `AMR_genotypes_core` : Gènes AMR du noyau de référence.
10. `number_amr_genes` : Nombre total de gènes de résistance identifiés par isolat.

