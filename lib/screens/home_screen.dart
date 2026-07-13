Widget _buildHomeContent() {
  return CustomScrollView(
    slivers: [
      // 1. Banner Promo (SliverToBoxAdapter untuk widget non-list)
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Container(
            height: 140,
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFF5722), Color(0xFFFF8A65)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFF5722).withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: Text(
                'Nusopa.Mart\nSederhana tapi Mewah',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  color: Colors.white, 
                  fontSize: 18, 
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ),
      ),
      
      // 2. Judul Rekomendasi
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 4.0),
          child: Text(
            'Rekomendasi Produk',
            style: GoogleFonts.inter(
              fontSize: 16, 
              fontWeight: FontWeight.bold, 
              color: Colors.black87,
            ),
          ),
        ),
      ),
      
      // 3. GridView Produk yang Efisien (Menggunakan SliverGrid)
      SliverPadding(
        padding: const EdgeInsets.all(16),
        sliver: SliverGrid(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.75,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          // Ubah itemCount menjadi berapa saja (misal 50), performa tetap ringan!
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              return GestureDetector(
                onTap: () {
                  // Aksi ketika produk diklik (Pindah ke Detail Produk)
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Membuka Produk Sembako $index')),
                  );
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.orange.shade50,
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(16),
                            ),
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.fastfood, 
                              size: 50, 
                              color: Color(0xFFFF5722),
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Produk Sembako $index', 
                              maxLines: 1, 
                              overflow: TextOverflow.ellipsis, 
                              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Rp 15.000', 
                              style: GoogleFonts.inter(
                                color: const Color(0xFFFF5722), 
                                fontWeight: FontWeight.bold, 
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      )
                    ],
                  ),
                ),
              );
            },
            childCount: 4, // Tentukan jumlah produk di sini
          ),
        ),
      ),
    ],
  );
}
