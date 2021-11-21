  hpcc_end:

  HPCC_Finalize( &params );

  HPCC_external_finalize( argc, argv, extdata );

  MPI_Finalize();
  return 0;
}

