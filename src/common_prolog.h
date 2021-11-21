#include <hpcc.h>
#include <ctype.h>

int main(int argc, char *argv[]) {
  int myRank, commSize;
  HPCC_Params params;
  void *extdata;

  MPI_Init( &argc, &argv );

  if (HPCC_external_init( argc, argv, &extdata ))
    goto hpcc_end;

  if (HPCC_Init( &params ))
    goto hpcc_end;

  MPI_Comm_size( MPI_COMM_WORLD, &commSize );
  MPI_Comm_rank( MPI_COMM_WORLD, &myRank );

  MPI_Barrier( MPI_COMM_WORLD );

